import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:elapsa/core/theme.dart';
import 'package:elapsa/domain/mrz.dart';
import 'package:elapsa/l10n/app_localizations.dart';
import 'package:elapsa/services/mrz_scanner.dart';
import 'package:elapsa/services/vision_channel.dart';

/// Everything one scanning session produced.
///
/// A document is not one picture. A card has two sides, a residence permit has
/// a page of stamps, and the data page of a passport is only half the story —
/// so the session collects an ordered set and keeps the best code it saw
/// across all of them.
class ScanSession {
  final List<Uint8List> images;
  final MrzResult? mrz;

  const ScanSession(this.images, this.mrz);
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

enum _Stage { starting, ready, noCamera, working }

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  static const _scanner = MrzScanner();
  static const _vision = VisionChannel();

  /// Detection runs far slower than the preview. Six a second is enough for
  /// the guide to feel live and leaves the channel free for everything else.
  static const _detectInterval = Duration(milliseconds: 160);

  CameraController? _controller;
  _Stage _stage = _Stage.starting;
  String? _message;

  CardQuad? _quad;
  DateTime _lastDetect = DateTime.fromMillisecondsSinceEpoch(0);
  bool _detecting = false;

  final _pages = <Uint8List>[];
  MrzResult? _bestMrz;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _startCamera();
    }
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw CameraException('none', 'No cameras');

      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        // yuv420 gives a separate luminance plane, which is all the rectangle
        // detector needs and a quarter the bytes of BGRA.
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.startImageStream(_onFrame);
      setState(() {
        _controller = controller;
        _stage = _Stage.ready;
      });
    } catch (_) {
      // No camera, or permission refused. Neither is fatal — the photo library
      // gets the user where they are going, and this is also the simulator's
      // situation and that of many cheap Android tablets.
      if (mounted) setState(() => _stage = _Stage.noCamera);
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_detecting || _stage == _Stage.working) return;
    if (DateTime.now().difference(_lastDetect) < _detectInterval) return;

    _detecting = true;
    _lastDetect = DateTime.now();
    try {
      final plane = image.planes.first;
      final found = await _vision.detectCard(
        luma: plane.bytes,
        width: image.width,
        height: image.height,
        bytesPerRow: plane.bytesPerRow,
      );
      if (!mounted) return;

      setState(() {
        final previous = _quad;
        // Ease towards the new reading so the guide glides rather than
        // twitching on every detection.
        _quad = (previous == null || found == null)
            ? found
            : previous.lerpTo(found, 0.5);
      });
    } catch (_) {
      // A dropped frame is not worth reporting; the next one is 160ms away.
    } finally {
      _detecting = false;
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final l = L.of(context);

    setState(() {
      _stage = _Stage.working;
      _message = null;
    });
    HapticFeedback.mediumImpact();

    try {
      final shot = await controller.takePicture();
      await _absorb(await _scanner.scanFile(shot.path));
    } catch (error, stack) {
      debugPrint('Elapsa: capture failed: $error\n$stack');
      _fail(l.scanFailedCapture);
    }
  }

  Future<void> _pickFromLibrary() async {
    setState(() {
      _stage = _Stage.working;
      _message = null;
    });

    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) {
        _restore();
        return;
      }
      await _absorb(await _scanner.scanFile(picked.path));
    } catch (error, stack) {
      debugPrint('Elapsa: scan from library failed: $error\n$stack');
      if (mounted) _fail(L.of(context).scanFailedPhoto);
    }
  }

  /// Files one captured page.
  ///
  /// A page without a readable code is still kept — the back of a card rarely
  /// has one, and throwing the picture away because of that would be absurd.
  /// The first trustworthy code seen wins, and later pages cannot overwrite it
  /// with something worse.
  Future<void> _absorb(ScanResult result) async {
    if (!mounted) return;

    if (result.cardImage != null) {
      _pages.add(result.cardImage!);
    }
    if (result.isTrustworthy && _bestMrz == null) {
      _bestMrz = result.mrz;
    }

    final l = L.of(context);
    setState(() {
      _stage = _controller != null ? _Stage.ready : _Stage.noCamera;
      if (result.cardImage == null) {
        _message = l.scanFailedPhoto;
      } else if (_bestMrz == null && result.isUnreadable) {
        _message = l.scanFailedUnreadable;
      } else if (_bestMrz == null) {
        _message = l.scanFailedNoCode;
      } else {
        _message = null;
      }
    });
  }

  void _restore() {
    if (!mounted) return;
    setState(() =>
        _stage = _controller != null ? _Stage.ready : _Stage.noCamera);
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _stage = _controller != null ? _Stage.ready : _Stage.noCamera;
      _message = message;
    });
  }

  void _finish() {
    if (_pages.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(ScanSession(List.of(_pages), _bestMrz));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final hasCamera = _controller != null && _stage != _Stage.noCamera;
    final busy = _stage == _Stage.working;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          l.scanTitle,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_pages.isNotEmpty)
            TextButton(
              onPressed: _finish,
              child: Text(
                l.actionDone,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (hasCamera)
            _CameraLayer(controller: _controller!)
          else if (_stage == _Stage.noCamera)
            _NoCameraLayer(l: l)
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          if (hasCamera)
            _CornerGuide(
              quad: _quad,
              controller: _controller!,
              dimmed: busy,
            ),

          if (busy)
            const ColoredBox(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          _Controls(
            l: l,
            message: _message,
            hasCamera: hasCamera,
            found: _quad != null,
            busy: busy,
            pages: _pages,
            onCapture: hasCamera && !busy ? _capture : null,
            onPickPhoto: busy ? null : _pickFromLibrary,
            onManual: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _CameraLayer extends StatelessWidget {
  const _CameraLayer({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final preview = controller.value.previewSize;
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        // The sensor delivers landscape; the preview is shown portrait.
        width: preview?.height ?? 1,
        height: preview?.width ?? 1,
        child: CameraPreview(controller),
      ),
    );
  }
}

/// Four right angles tracking the detected card.
///
/// Corner brackets rather than a full outline: they read as "line this up"
/// where a closed rectangle reads as a fixed frame the user must fit the card
/// into. The card can sit at an angle and the guide follows it, which is what
/// tells the user the app has actually seen the document.
class _CornerGuide extends StatelessWidget {
  const _CornerGuide({
    required this.quad,
    required this.controller,
    required this.dimmed,
  });

  final CardQuad? quad;
  final CameraController controller;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return AnimatedOpacity(
            opacity: quad == null ? 0.45 : (dimmed ? 0.3 : 1),
            duration: const Duration(milliseconds: 180),
            child: CustomPaint(
              painter: _CornerPainter(
                quad: quad,
                colour: quad == null ? Colors.white : kBrand,
                previewSize: controller.value.previewSize,
                canvas: size,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({
    required this.quad,
    required this.colour,
    required this.previewSize,
    required this.canvas,
  });

  final CardQuad? quad;
  final Color colour;
  final Size? previewSize;
  final Size canvas;

  @override
  void paint(Canvas canvas, Size size) {
    final corners = _screenCorners(size);
    final paint = Paint()
      ..color = colour
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Bracket arms are a fraction of each edge, so they scale with the card
    // rather than looking oversized when it is far away.
    for (var i = 0; i < 4; i++) {
      final corner = corners[i];
      final next = corners[(i + 1) % 4];
      final previous = corners[(i + 3) % 4];

      canvas.drawPath(
        Path()
          ..moveTo(_along(corner, previous, 0.22).dx,
              _along(corner, previous, 0.22).dy)
          ..lineTo(corner.dx, corner.dy)
          ..lineTo(_along(corner, next, 0.22).dx, _along(corner, next, 0.22).dy),
        paint,
      );
    }
  }

  static Offset _along(Offset from, Offset to, double t) =>
      Offset.lerp(from, to, t)!;

  /// Maps the detected quad into the widget's pixel space.
  ///
  /// Three transforms compose here: the sensor delivers landscape while the
  /// preview is shown portrait (a quarter turn), the preview is fitted with
  /// BoxFit.cover (a scale plus a centring offset), and Vision's normalised
  /// points have already been flipped to a top-left origin upstream.
  List<Offset> _screenCorners(Size size) {
    final quad = this.quad;
    if (quad == null) return _defaultFrame(size);

    final preview = previewSize;
    // Sensor frame rotated a quarter turn into portrait.
    final sourceWidth = preview?.height ?? size.width;
    final sourceHeight = preview?.width ?? size.height;

    final scale = math.max(size.width / sourceWidth, size.height / sourceHeight);
    final dx = (size.width - sourceWidth * scale) / 2;
    final dy = (size.height - sourceHeight * scale) / 2;

    return quad.points.map((p) {
      // Quarter turn: a point across the landscape buffer becomes a point down
      // the portrait preview.
      final rotated = Offset(1 - p.dy, p.dx);
      return Offset(
        rotated.dx * sourceWidth * scale + dx,
        rotated.dy * sourceHeight * scale + dy,
      );
    }).toList();
  }

  /// Where the brackets rest before anything is detected — a card-shaped hint
  /// in the middle of the frame.
  List<Offset> _defaultFrame(Size size) {
    final width = size.width * 0.82;
    final height = width / kCardAspectRatio;
    final left = (size.width - width) / 2;
    final top = (size.height - height) / 2;
    return [
      Offset(left, top),
      Offset(left + width, top),
      Offset(left + width, top + height),
      Offset(left, top + height),
    ];
  }

  @override
  bool shouldRepaint(_CornerPainter old) =>
      old.quad != quad || old.colour != colour;
}

class _NoCameraLayer extends StatelessWidget {
  const _NoCameraLayer({required this.l});

  final L l;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 44),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library_outlined,
                size: 52, color: Colors.white38),
            const SizedBox(height: 20),
            Text(
              l.scanNoCameraTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              l.scanNoCameraBody,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.l,
    required this.message,
    required this.hasCamera,
    required this.found,
    required this.busy,
    required this.pages,
    required this.onCapture,
    required this.onPickPhoto,
    required this.onManual,
  });

  final L l;
  final String? message;
  final bool hasCamera;
  final bool found;
  final bool busy;
  final List<Uint8List> pages;
  final VoidCallback? onCapture;
  final VoidCallback? onPickPhoto;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pages.isNotEmpty) ...[
                _PageStrip(pages: pages),
                const SizedBox(height: 14),
              ],

              Text(
                message ??
                    (hasCamera
                        ? (found ? l.scanHintFound : l.scanHintSearching)
                        : l.scanHintNoCamera),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: message != null ? Colors.white : Colors.white70,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),

              // A circle with a centred glyph and no text, so it looks
              // identical however the phone is held — the reason there is no
              // label on it.
              if (hasCamera)
                _ShutterButton(enabled: !busy, armed: found, onTap: onCapture),

              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: onPickPhoto,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: Text(l.scanChoosePhoto),
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  ),
                  if (pages.isEmpty)
                    TextButton(
                      onPressed: onManual,
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.white70),
                      child: Text(l.scanEnterByHand),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({
    required this.enabled,
    required this.armed,
    required this.onTap,
  });

  final bool enabled;

  /// True once a card is detected — the button fills with the brand colour, so
  /// the user is told when the shot is worth taking without a word of text.
  final bool armed;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: L.of(context).actionScan,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: armed ? kBrand : Colors.white24,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Icon(
            Icons.document_scanner_outlined,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _PageStrip extends StatelessWidget {
  const _PageStrip({required this.pages});

  final List<Uint8List> pages;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: pages.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.memory(
            pages[index],
            width: 54 * kCardAspectRatio,
            height: 54,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
