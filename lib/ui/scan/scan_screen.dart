import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:elapsa/domain/mrz.dart';
import 'package:elapsa/services/card_cropper.dart';
import 'package:elapsa/services/mrz_scanner.dart';
import 'package:elapsa/ui/widgets/document_card_face.dart' show kCardAspectRatio;

/// What a successful scan hands back: the parsed code, and the card image
/// cropped to the guide the user framed it in.
///
/// [cardImage] is null when the photo could not be decoded — the document is
/// still perfectly usable, it just gets the designed card face instead.
class ScanCapture {
  final MrzResult mrz;
  final Uint8List? cardImage;

  const ScanCapture(this.mrz, this.cardImage);
}

/// Scans the machine-readable zone on a passport, ID card or visa.
///
/// Pops with a [ScanCapture] once the check digits validate.
///
/// Capture is on a button rather than a live frame stream. A still photo goes
/// through the same accurate recognition path on both platforms, needs no
/// per-platform pixel-format handling, and — because the MRZ is small, dense
/// type — a deliberate, steady shot reads far better than a stream of frames
/// caught mid-move.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

enum _Stage { starting, ready, noCamera, working }

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  static const _scanner = MrzScanner();
  static const _cropper = CardCropper();

  CameraController? _controller;
  _Stage _stage = _Stage.starting;
  String? _message;
  bool _handled = false;

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
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _stage = _Stage.ready;
      });
    } catch (_) {
      // No camera, or permission refused. Neither is fatal — the photo
      // library gets the user where they are going, and this is also the
      // simulator's situation and that of many cheap Android tablets.
      if (mounted) setState(() => _stage = _Stage.noCamera);
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() {
      _stage = _Stage.working;
      _message = null;
    });

    try {
      final shot = await controller.takePicture();
      await _handle(await _scanner.scanFile(shot.path), shot.path);
    } catch (error, stack) {
      debugPrint('Elapsa: capture failed: $error\n$stack');
      _fail('Could not take that photo. Try again.');
    }
  }

  /// Reads the code from the full-resolution photo, then crops a card face
  /// from the same capture.
  ///
  /// The order matters: OCR gets every pixel of the machine-readable zone,
  /// while the stored face is trimmed to the guide. Cropping first would throw
  /// away detail the recogniser wants.
  Future<Uint8List?> _cardFaceFrom(String path) =>
      _cropper.cropToCard(path, aspectRatio: kCardAspectRatio);

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
      await _handle(await _scanner.scanFile(picked.path), picked.path);
    } catch (error, stack) {
      // Surface the real cause in debug. A generic "could not read" message
      // hides platform-channel failures behind what looks like a bad photo.
      debugPrint('Elapsa: scan from library failed: $error\n$stack');
      _fail('Could not read that photo.');
    }
  }

  Future<void> _handle(ScanOutcome outcome, String imagePath) async {
    switch (outcome) {
      case ScanSucceeded(:final result):
        _finish(result, await _cardFaceFrom(imagePath));
      case ScanUnreadable():
        _fail('Found the code but could not read it cleanly. Try again with '
            'less glare, or enter the details by hand.');
      case ScanFoundNothing():
        _fail('No document code found. Fill the frame with the card and make '
            'sure the lines of code along the bottom are sharp.');
    }
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

  void _finish(MrzResult result, Uint8List? cardImage) {
    if (_handled) return;
    _handled = true;
    HapticFeedback.mediumImpact();
    if (mounted) {
      Navigator.of(context).pop(ScanCapture(result, cardImage));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCamera = _controller != null && _stage != _Stage.noCamera;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Scan document',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (hasCamera)
            _CameraLayer(controller: _controller!)
          else if (_stage == _Stage.noCamera)
            const _NoCameraLayer()
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          if (hasCamera && _stage != _Stage.working) const _CardGuide(),

          if (_stage == _Stage.working)
            const ColoredBox(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          _BottomBar(
            message: _message,
            hint: hasCamera
                ? 'Fill the frame with the card, code along the bottom. This '
                    'is also the picture you will see in your wallet.'
                : 'No camera on this device — read the code from a photo instead.',
            onCapture: hasCamera && _stage != _Stage.working ? _capture : null,
            onPickPhoto: _stage == _Stage.working ? null : _pickFromLibrary,
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
    // Fill the screen without distorting the preview's aspect ratio.
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.previewSize?.height ?? 1,
        height: controller.value.previewSize?.width ?? 1,
        child: CameraPreview(controller),
      ),
    );
  }
}

class _NoCameraLayer extends StatelessWidget {
  const _NoCameraLayer();

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
              'Scan from a photo',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Elapsa can read the code from a picture of a document you '
              'already have.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// The card-shaped frame the user fills.
///
/// It does double duty. It tells the recogniser roughly where to expect the
/// machine-readable zone, and — because the capture is cropped to exactly this
/// rectangle — it is also the composition of the card face that ends up in the
/// user's wallet. What they frame is what they get.
class _CardGuide extends StatelessWidget {
  const _CardGuide();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.9,
          child: AspectRatio(
            aspectRatio: kCardAspectRatio,
            child: Stack(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // Marks the band along the bottom where the code sits, so the
                // user knows which way up to hold the document.
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'code this end  <<<<<',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.message,
    required this.hint,
    required this.onCapture,
    required this.onPickPhoto,
    required this.onManual,
  });

  final String? message;
  final String hint;
  final VoidCallback? onCapture;
  final VoidCallback? onPickPhoto;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: message != null ? const EdgeInsets.all(14) : null,
                decoration: message != null
                    ? BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: Text(
                  message ?? hint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: message != null ? Colors.white : Colors.white70,
                    height: 1.45,
                  ),
                ),
              ),
              if (onCapture != null)
                FilledButton.icon(
                  onPressed: onCapture,
                  icon: const Icon(Icons.center_focus_strong),
                  label: const Text('Scan'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              if (onCapture != null) const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onPickPhoto,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose a photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              TextButton(
                onPressed: onManual,
                child: const Text(
                  'Enter details by hand',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
