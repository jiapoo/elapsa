import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The four corners of a detected card, normalised 0-1.
///
/// Points arrive in the frame's own coordinate space with a **top-left**
/// origin — [VisionChannel] flips Vision's bottom-left convention on the way
/// out so the rest of the app only ever deals with screen-like coordinates.
class CardQuad {
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomRight;
  final Offset bottomLeft;
  final double confidence;

  const CardQuad({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
    required this.confidence,
  });

  List<Offset> get points => [topLeft, topRight, bottomRight, bottomLeft];

  /// Interpolates towards [other], so the on-screen guide glides between
  /// detections instead of snapping on every frame.
  CardQuad lerpTo(CardQuad other, double t) => CardQuad(
        topLeft: Offset.lerp(topLeft, other.topLeft, t)!,
        topRight: Offset.lerp(topRight, other.topRight, t)!,
        bottomRight: Offset.lerp(bottomRight, other.bottomRight, t)!,
        bottomLeft: Offset.lerp(bottomLeft, other.bottomLeft, t)!,
        confidence: other.confidence,
      );
}

/// On-device Vision, over a platform channel.
///
/// This is a channel rather than a Dart package on purpose: the ML Kit plugin
/// drags in an iOS SDK built as a legacy fat framework whose arm64 slice is
/// device-only, which forces the whole app to x86_64 and makes it
/// uninstallable on an Apple Silicon simulator. Apple Vision has no such
/// problem, costs nothing in app size, and reads Chinese better.
class VisionChannel {
  const VisionChannel();

  static const _channel = MethodChannel('cc.elapsa/vision');

  /// Every line of text in the image at [path], newline separated.
  Future<String> recognize(String path) async {
    final text = await _channel.invokeMethod<String>('recognize', {
      'path': path,
    });
    return text ?? '';
  }

  /// Looks for a card in a live preview frame.
  ///
  /// Takes only the luminance plane — rectangle detection does not need
  /// colour, and one byte per pixel instead of four is the difference between
  /// a smooth preview and a stuttering one.
  Future<CardQuad?> detectCard({
    required Uint8List luma,
    required int width,
    required int height,
    required int bytesPerRow,
  }) async {
    final raw = await _channel.invokeMapMethod<String, dynamic>('detectCard', {
      'bytes': luma,
      'width': width,
      'height': height,
      'bytesPerRow': bytesPerRow,
    });
    if (raw == null) return null;

    Offset point(String key) {
      final p = (raw[key] as Map).cast<String, dynamic>();
      // Vision's origin is bottom-left; everything above this line is
      // screen-like, so flip once, here.
      return Offset(
        (p['x'] as num).toDouble(),
        1.0 - (p['y'] as num).toDouble(),
      );
    }

    return CardQuad(
      topLeft: point('topLeft'),
      topRight: point('topRight'),
      bottomRight: point('bottomRight'),
      bottomLeft: point('bottomLeft'),
      confidence: (raw['confidence'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Detects the card in a full-resolution capture and flattens it.
  ///
  /// Perspective correction is what separates this from a crop: a card
  /// photographed at an angle comes back square-on, the way it would look on a
  /// scanner bed. Returns null when no card is found, and the caller falls
  /// back to a centre crop.
  Future<Uint8List?> extractCard(String path) async {
    try {
      return await _channel.invokeMethod<Uint8List>('extractCard', {
        'path': path,
      });
    } on PlatformException catch (error) {
      debugPrint('Elapsa: extractCard failed: $error');
      return null;
    }
  }
}
