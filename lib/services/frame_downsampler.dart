import 'dart:typed_data';

/// A luminance buffer, packed with no row padding.
class LumaFrame {
  final Uint8List bytes;
  final int width;
  final int height;

  const LumaFrame(this.bytes, this.width, this.height);
}

/// Shrinks a camera luminance plane before it crosses the platform channel.
///
/// At 1280x720 a single plane is close to a megabyte, and sending one several
/// times a second saturates the channel — which is what makes a live preview
/// feel heavy. Rectangle detection wants edges rather than detail, and the card
/// has to fill a good share of the frame anyway, so a fraction of the pixels
/// finds it just as well at a fraction of the cost.
///
/// Nearest-neighbour on purpose: averaging would soften precisely the edges
/// being looked for, and cost more to do it.
///
/// The result is always freshly packed, even when no shrinking is needed.
/// Camera planes are usually padded — `bytesPerRow` is rounded up for
/// alignment — and handing those bytes on while claiming the row stride equals
/// the width shears the picture into diagonal nonsense that no detector will
/// ever find a rectangle in.
LumaFrame downsampleLuma(
  Uint8List source, {
  required int width,
  required int height,
  required int bytesPerRow,
  required int targetWidth,
}) {
  final step = width <= targetWidth ? 1 : (width / targetWidth).floor();
  final outWidth = width ~/ step;
  final outHeight = height ~/ step;

  final out = Uint8List(outWidth * outHeight);
  var target = 0;
  for (var y = 0; y < outHeight; y++) {
    final row = y * step * bytesPerRow;
    for (var x = 0; x < outWidth; x++) {
      out[target++] = source[row + x * step];
    }
  }
  return LumaFrame(out, outWidth, outHeight);
}
