import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:elapsa/core/theme.dart';
import 'package:elapsa/domain/mrz.dart';
import 'package:elapsa/domain/printed_fields.dart';
import 'package:elapsa/l10n/app_localizations.dart';
import 'package:elapsa/services/mrz_scanner.dart';
import 'package:elapsa/services/vision_channel.dart';

/// Everything one scanning session produced.
///
/// A document is not one picture. A card has two sides, a residence permit has
/// a page of stamps, and the data page of a passport is only half the story —
/// so the session collects an ordered set and keeps the best reading it saw
/// across all of them.
class ScanSession {
  final List<Uint8List> images;
  final MrzResult? mrz;
  final PrintedFields printed;

  const ScanSession(this.images, this.mrz, this.printed);
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

  /// How square-on the card must be before the shutter arms.
  ///
  /// At 0.93 the shorter of two opposite edges is within 7% of the longer,
  /// which for a card at arm's length is a tilt of a few degrees — small
  /// enough that cropping without any perspective warp loses nothing.
  static const _flatEnough = 0.93;

  CameraController? _controller;
  _Stage _stage = _Stage.starting;

  CardQuad? _quad;
  Size? _frameSize;
  DateTime _lastDetect = DateTime.fromMillisecondsSinceEpoch(0);
  bool _detecting = false;

  final _pages = <Uint8List>[];
  MrzResult? _bestMrz;
  PrintedFields _printed = PrintedFields.empty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Portrait only while scanning. A fixed orientation means the controls
    // never move under the user's thumb mid-scan, and it removes a whole class
    // of overlay bug: the guide only ever has to account for one rotation
    // between the sensor and the screen instead of four.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
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
        _frameSize = Size(image.width.toDouble(), image.height.toDouble());
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

  /// How square-on the card currently is, or null when none is detected.
  double? get _flatness {
    final quad = _quad;
    final frame = _frameSize;
    if (quad == null || frame == null) return null;
    return quad.flatness(frame);
  }

  bool get _armed => (_flatness ?? 0) >= _flatEnough;

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() => _stage = _Stage.working);
    HapticFeedback.mediumImpact();

    try {
      final shot = await controller.takePicture();
      _absorb(await _scanner.scanFile(shot.path));
    } catch (error, stack) {
      debugPrint('Elapsa: capture failed: $error\n$stack');
      _restore();
    }
  }

  Future<void> _pickFromLibrary() async {
    setState(() => _stage = _Stage.working);
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) {
        _restore();
        return;
      }
      _absorb(await _scanner.scanFile(picked.path));
    } catch (error, stack) {
      debugPrint('Elapsa: scan from library failed: $error\n$stack');
      _restore();
    }
  }

  /// Files one captured page.
  ///
  /// A page with nothing readable is still kept — the front of a card rarely
  /// carries the expiry, and discarding the picture for that would be absurd.
  /// The first trusted reading wins, so a later page cannot overwrite it with
  /// something worse.
  void _absorb(ScanResult result) {
    if (!mounted) return;

    setState(() {
      if (result.cardImage != null) _pages.add(result.cardImage!);
      if (result.hasTrustedCode && _bestMrz == null) _bestMrz = result.mrz;
      if (_printed.isEmpty && !result.printed.isEmpty) {
        _printed = result.printed;
      }
      _stage = _controller != null ? _Stage.ready : _Stage.noCamera;
    });
  }

  void _restore() {
    if (!mounted) return;
    setState(() =>
        _stage = _controller != null ? _Stage.ready : _Stage.noCamera);
  }

  void _finish() {
    if (_pages.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.of(context)
        .pop(ScanSession(List.of(_pages), _bestMrz, _printed));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final hasCamera = _controller != null && _stage != _Stage.noCamera;
    final busy = _stage == _Stage.working;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (hasCamera)
            _CameraLayer(controller: _controller!)
          else if (_stage == _Stage.noCamera)
            const _NoCameraLayer()
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          if (hasCamera)
            _CornerGuide(
              quad: _quad,
              frameSize: _frameSize,
              controller: _controller!,
              armed: _armed,
              dimmed: busy,
            ),

          if (busy)
            const ColoredBox(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          SafeArea(
            child: Stack(
              children: [
                // Back, top left. The only chrome at the top — a title would
                // be text over the very thing the user is trying to look at.
                Align(
                  alignment: Alignment.topLeft,
                  child: _GlyphButton(
                    icon: Icons.arrow_back_ios_new,
                    semantic: l.actionCancel,
                    onTap: busy ? null : () => Navigator.of(context).pop(),
                  ),
                ),

                if (_pages.isNotEmpty)
                  Align(
                    alignment: Alignment.topRight,
                    child: _GlyphButton(
                      icon: Icons.check,
                      semantic: l.actionDone,
                      filled: true,
                      onTap: busy ? null : _finish,
                    ),
                  ),

                // Controls along the bottom, where a thumb rests when the
                // phone is held upright.
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_pages.isNotEmpty) ...[
                          _PageStrip(pages: _pages),
                          const SizedBox(height: 18),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _GlyphButton(
                              icon: Icons.photo_library_outlined,
                              semantic: l.scanChoosePhoto,
                              onTap: busy ? null : _pickFromLibrary,
                            ),
                            const SizedBox(width: 26),
                            _Shutter(
                              armed: _armed,
                              enabled: hasCamera && !busy,
                              semantic: l.actionScan,
                              onTap: _capture,
                            ),
                            const SizedBox(width: 26),
                            _GlyphButton(
                              icon: Icons.keyboard_outlined,
                              semantic: l.scanEnterByHand,
                              onTap:
                                  busy ? null : () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
    // The sensor delivers landscape while the screen is portrait, so the
    // preview's dimensions are swapped before being fitted.
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: preview?.height ?? 1,
        height: preview?.width ?? 1,
        child: CameraPreview(controller),
      ),
    );
  }
}

class _NoCameraLayer extends StatelessWidget {
  const _NoCameraLayer();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.photo_library_outlined, size: 52, color: Colors.white38),
    );
  }
}

/// Four right angles tracking the detected card.
///
/// Corner brackets rather than a closed outline: they read as "line this up"
/// where a full rectangle reads as a fixed frame to fit the card into. Colour
/// carries the whole instruction — white while searching, amber once found but
/// tilted, brand red when the card is square on and the shot is worth taking.
/// The brackets on the far edge stay dim until then, which shows the user
/// which way to move without a word of text.
class _CornerGuide extends StatelessWidget {
  const _CornerGuide({
    required this.quad,
    required this.frameSize,
    required this.controller,
    required this.armed,
    required this.dimmed,
  });

  final CardQuad? quad;
  final Size? frameSize;
  final CameraController controller;
  final bool armed;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: dimmed ? 0.25 : 1,
        duration: const Duration(milliseconds: 180),
        child: CustomPaint(
          painter: _CornerPainter(
            quad: quad,
            armed: armed,
            farEdge: quad?.farthestEdge,
            previewSize: controller.value.previewSize,
            rotation: _rotationDegrees(controller),
          ),
        ),
      ),
    );
  }

  /// Degrees the sensor image must be rotated to match what is on screen.
  ///
  /// Locked to portrait this is normally a quarter turn, but it is derived
  /// rather than assumed: sensor mounting differs between devices, and a
  /// hard-coded guess is exactly how an overlay ends up square to nothing.
  static int _rotationDegrees(CameraController controller) {
    const deviceDegrees = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };
    final device = deviceDegrees[controller.value.deviceOrientation] ?? 0;
    final sensor = controller.description.sensorOrientation;
    return (sensor - device + 360) % 360;
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({
    required this.quad,
    required this.armed,
    required this.farEdge,
    required this.previewSize,
    required this.rotation,
  });

  final CardQuad? quad;
  final bool armed;
  final CardEdge? farEdge;
  final Size? previewSize;
  final int rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final corners = _screenCorners(size);
    final colour = quad == null
        ? Colors.white
        : (armed ? kBrand : const Color(0xFFFFB300));

    for (var i = 0; i < 4; i++) {
      final corner = corners[i];
      final next = corners[(i + 1) % 4];
      final previous = corners[(i + 3) % 4];

      // Dim the two corners on the edge that is furthest away, so the shape
      // itself says "bring this side closer".
      final onFarEdge = !armed && quad != null && _touchesFarEdge(i);
      final paint = Paint()
        ..color = colour.withValues(alpha: onFarEdge ? 0.3 : 1)
        ..strokeWidth = armed ? 5 : 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Bracket arms are a fraction of each edge, so they scale with the card
      // rather than looking oversized when it is far away.
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

  /// Corners are indexed top-left, top-right, bottom-right, bottom-left.
  bool _touchesFarEdge(int corner) => switch (farEdge) {
        CardEdge.top => corner == 0 || corner == 1,
        CardEdge.right => corner == 1 || corner == 2,
        CardEdge.bottom => corner == 2 || corner == 3,
        CardEdge.left => corner == 3 || corner == 0,
        null => false,
      };

  static Offset _along(Offset from, Offset to, double t) =>
      Offset.lerp(from, to, t)!;

  /// Maps the detected quad into the widget's pixel space.
  ///
  /// Two transforms compose: the sensor's mounting rotation relative to the
  /// screen, then the BoxFit.cover the preview is displayed with. Vision's
  /// bottom-left origin was already flipped upstream.
  List<Offset> _screenCorners(Size size) {
    final quad = this.quad;
    if (quad == null) return _restingFrame(size);

    final preview = previewSize ?? size;
    final quarterTurn = rotation == 90 || rotation == 270;
    final sourceWidth = quarterTurn ? preview.height : preview.width;
    final sourceHeight = quarterTurn ? preview.width : preview.height;

    final scale = math.max(size.width / sourceWidth, size.height / sourceHeight);
    final dx = (size.width - sourceWidth * scale) / 2;
    final dy = (size.height - sourceHeight * scale) / 2;

    return quad.points.map((p) {
      final r = _rotate(p, rotation);
      return Offset(
        r.dx * sourceWidth * scale + dx,
        r.dy * sourceHeight * scale + dy,
      );
    }).toList();
  }

  /// Rotates a point in normalised space.
  static Offset _rotate(Offset p, int degrees) => switch (degrees) {
        90 => Offset(1 - p.dy, p.dx),
        180 => Offset(1 - p.dx, 1 - p.dy),
        270 => Offset(p.dy, 1 - p.dx),
        _ => p,
      };

  /// Where the brackets rest before anything is detected — a card-shaped hint
  /// in the middle of the frame.
  List<Offset> _restingFrame(Size size) {
    // A card is a landscape object even when the phone is upright, so the
    // resting guide is wide and shallow — it shows how to hold the document,
    // not how to hold the phone.
    final width = math.min(size.width * 0.86, size.height * 0.7 * kCardAspectRatio);
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
      old.quad != quad ||
      old.armed != armed ||
      old.farEdge != farEdge ||
      old.rotation != rotation;
}

/// The shutter. A circle with a centred glyph and no label, which is what
/// makes it look identical however the phone is held.
class _Shutter extends StatelessWidget {
  const _Shutter({
    required this.armed,
    required this.enabled,
    required this.semantic,
    required this.onTap,
  });

  final bool armed;
  final bool enabled;
  final String semantic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled && armed,
      label: semantic,
      child: GestureDetector(
        onTap: enabled && armed ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Filling with the brand colour is the whole signal that the card
            // is square on and the shot is worth taking.
            color: armed ? kBrand : Colors.white24,
            border: Border.all(
              color: Colors.white.withValues(alpha: armed ? 1 : 0.55),
              width: 4,
            ),
          ),
          child: Icon(
            Icons.photo_camera_outlined,
            color: Colors.white.withValues(alpha: armed ? 1 : 0.6),
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _GlyphButton extends StatelessWidget {
  const _GlyphButton({
    required this.icon,
    required this.semantic,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String semantic;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantic,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? kBrand : Colors.black.withValues(alpha: 0.4),
            ),
            child: Icon(icon, color: Colors.white, size: 21),
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
