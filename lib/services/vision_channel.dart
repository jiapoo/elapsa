import 'dart:math' as math;
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The card cut out of a photo, and where it was cut from.
///
/// The region comes back with the bytes so the caller can check what the crop
/// left behind. A detector finds *a* rectangle, not necessarily the right one,
/// and on a document the wrong one is often a panel inside the page.
class CardCut {
  final Uint8List bytes;

  /// The crop's own bounds in the original photo, normalised, top-left origin.
  final Rect bounds;

  const CardCut(this.bytes, this.bounds);
}

/// The scripts to read, in the order they should be tried.
///
/// Vision treats this list as priority rather than as a set: the language it
/// tries first is the one it resolves an ambiguous glyph towards. So the order
/// is a real decision, and the app already knows the answer — whichever
/// language the user chose in Settings is the one their documents are most
/// likely to be printed in.
///
/// The others always follow rather than being dropped. Somebody reading the
/// app in Chinese still owns a passport with English on it.
List<String> recognitionLanguagesFor(Locale locale) {
  if (locale.languageCode != 'zh') {
    return const ['en-US', 'zh-Hans', 'zh-Hant'];
  }
  return locale.scriptCode == 'Hant'
      ? const ['zh-Hant', 'zh-Hans', 'en-US']
      : const ['zh-Hans', 'zh-Hant', 'en-US'];
}

/// What one pass of the recogniser found.
class Recognition {
  /// Every line it read, newline separated.
  final String text;

  /// Where all of that writing sits, as one box in normalised coordinates
  /// with a top-left origin, or null when nothing was read.
  ///
  /// This is the app's answer for a document that will not square up. An open
  /// passport has no outline to find — the data page runs into the facing page
  /// across the fold, and the pages curve away from flat — but the writing on
  /// it is unmistakable, and the writing is the part worth keeping.
  final Rect? bounds;

  const Recognition({required this.text, this.bounds});

  static const empty = Recognition(text: '');
}

/// Which edge of the card is furthest from the camera.
enum CardEdge { top, bottom, left, right }

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

  /// How square-on the card is, from 0 to 1.
  ///
  /// A rectangle photographed with the camera parallel to it projects to a
  /// rectangle: opposite edges come out the same length. Tilt the phone and
  /// the near edge grows while the far one shrinks, so comparing opposite
  /// edges measures the tilt directly — no motion sensors, and it works
  /// whether the card is on a table, on a wall, or in someone's hand.
  ///
  /// This is what lets Elapsa avoid perspective correction rather than perform
  /// it: hold the shutter until this reads high, and there is no perspective
  /// left to correct.
  ///
  /// Must be measured in pixels, not normalised units — the frame is not
  /// square, so normalised lengths are stretched along one axis and would
  /// report a tilt that is not there.
  double flatness(Size frame) {
    Offset px(Offset n) => Offset(n.dx * frame.width, n.dy * frame.height);

    final tl = px(topLeft);
    final tr = px(topRight);
    final br = px(bottomRight);
    final bl = px(bottomLeft);

    double ratio(double a, double b) {
      final longest = math.max(a, b);
      if (longest <= 0) return 0;
      return math.min(a, b) / longest;
    }

    return math.min(
      ratio((tr - tl).distance, (br - bl).distance),
      ratio((bl - tl).distance, (br - tr).distance),
    );
  }

  /// Which edge is furthest from the camera, or null when the card is square
  /// on.
  ///
  /// The far edge is the short one. Dimming its brackets shows the user which
  /// way to move without a word of instruction.
  CardEdge? get farthestEdge {
    final top = (topRight - topLeft).distance;
    final bottom = (bottomRight - bottomLeft).distance;
    final left = (bottomLeft - topLeft).distance;
    final right = (bottomRight - topRight).distance;

    final horizontal = (top - bottom).abs();
    final vertical = (left - right).abs();
    if (horizontal < 0.01 && vertical < 0.01) return null;

    if (horizontal >= vertical) {
      return top < bottom ? CardEdge.top : CardEdge.bottom;
    }
    return left < right ? CardEdge.left : CardEdge.right;
  }

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

  /// Loads the recognition models before they are needed.
  ///
  /// Vision pays for loading its language models on the first request. Left
  /// alone that cost lands on the first photo someone takes and reads as the
  /// app being slow, so it is paid while they are still lining the card up.
  Future<void> prewarm() async {
    try {
      await _channel.invokeMethod<void>('prewarm');
    } on PlatformException catch (error) {
      debugPrint('Elapsa: prewarm failed: $error');
    }
  }

  /// Every line of text in the image at [path], newline separated.
  /// Reads the text in the image at [path].
  ///
  /// [boost] asks for the pass tuned for embossed figures — greyscaled,
  /// sharpened and stretched, so a raised card number that has no tonal
  /// contrast at all becomes something a recogniser can see. It is worth
  /// running only when the plain pass came back without one: the same
  /// treatment blooms fine flat print and costs the fields that already read.
  /// [variant] picks which treatment: 0 flattens the illumination away, which
  /// is what a pale digit on a pale card needs; 1 sharpens and stretches,
  /// which is the better tool on a dark card. They fail in opposite
  /// conditions, so both are worth trying before giving up on a number.
  Future<Recognition> recognize(
    String path, {
    bool boost = false,
    int variant = 0,
    List<String>? languages,
  }) async {
    final reply = await _channel.invokeMapMethod<String, dynamic>('recognize', {
      'path': path,
      'boost': boost,
      'variant': variant,
      'languages': languages ?? const <String>[],
    });
    if (reply == null) return Recognition.empty;

    final box = (reply['bounds'] as Map?)?.cast<String, dynamic>();
    return Recognition(
      text: reply['text'] as String? ?? '',
      bounds: box == null
          ? null
          : Rect.fromLTWH(
              (box['x'] as num).toDouble(),
              (box['y'] as num).toDouble(),
              (box['width'] as num).toDouble(),
              (box['height'] as num).toDouble(),
            ),
    );
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

  /// Detects the card in a full-resolution capture and cuts it out.
  ///
  /// A rigid transform only — rotated to the card's own angle and cropped to
  /// its corners. No perspective warp, because a warp stretches the far edge
  /// to match the near one and smears exactly the small print an expiry date
  /// is written in. The scanner instead holds the shutter until [flatness]
  /// reads high, so there is no perspective left to correct.
  ///
  /// Returns null when no card is found, and the caller falls back to a centre
  /// crop.
  /// Cuts the document out of the photo at [path].
  ///
  /// [byHand] says the corners were placed by a person. Corners the detector
  /// found sit *on* the card's edge and are widened slightly so the border
  /// survives; corners a finger placed are exactly where the picture was meant
  /// to end, and widening those puts back the rim of desk the user had just
  /// finished removing.
  Future<CardCut?> extractCard(
    String path, {
    CardQuad? quad,
    bool byHand = false,
  }) async {
    try {
      final reply = await _channel.invokeMapMethod<String, dynamic>(
        'extractCard',
        {
          'path': path,
          'byHand': byHand,
          // The corners the scanner had locked on when the shutter fired. Sent
          // so the cut matches what the user was shown — re-detecting on the
          // still can settle on a different rectangle entirely.
          if (quad != null) 'corners': _encode(quad),
        },
      );
      if (reply == null) return null;

      final bytes = reply['bytes'];
      final box = (reply['bounds'] as Map?)?.cast<String, dynamic>();
      if (bytes is! Uint8List || box == null) return null;

      return CardCut(
        bytes,
        Rect.fromLTWH(
          (box['x'] as num).toDouble(),
          (box['y'] as num).toDouble(),
          (box['width'] as num).toDouble(),
          (box['height'] as num).toDouble(),
        ),
      );
    } on PlatformException catch (error) {
      debugPrint('Elapsa: extractCard failed: $error');
      return null;
    }
  }

  static Map<String, Map<String, double>> _encode(CardQuad quad) {
    Map<String, double> pair(Offset p) => {'x': p.dx, 'y': p.dy};
    return {
      'topLeft': pair(quad.topLeft),
      'topRight': pair(quad.topRight),
      'bottomRight': pair(quad.bottomRight),
      'bottomLeft': pair(quad.bottomLeft),
    };
  }
}
