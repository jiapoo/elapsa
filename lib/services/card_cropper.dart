import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Trims a captured photo down to the card the user framed.
///
/// The scanner shows a card-shaped guide and asks the user to fill it, so the
/// card sits centred in the frame at a known aspect ratio. Cropping to that
/// rectangle at capture time is what makes every stored card face actually
/// look like a card — far better than cropping at render time, where the app
/// can only guess which part of an arbitrary photo matters.
class CardCropper {
  const CardCropper();

  /// Longest edge of the stored image.
  ///
  /// A card face is displayed a few hundred points wide at most. Keeping a
  /// 12-megapixel original would mean encrypting, decrypting and decoding
  /// several megabytes to draw a list row — and would store far more detail of
  /// someone's passport than the feature needs.
  static const _maxEdge = 1600;

  /// Crops the image at [path] to [aspectRatio], centred, and re-encodes it.
  ///
  /// Returns null if the file cannot be decoded, in which case the caller
  /// should fall back to storing the original.
  Future<Uint8List?> cropToCard(
    String path, {
    required double aspectRatio,
  }) async {
    try {
      final bytes = await File(path).readAsBytes();

      // bakeOrientation applies the EXIF rotation, so the crop maths below
      // work on the image as the user actually saw it rather than as the
      // sensor happened to store it.
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final upright = img.bakeOrientation(decoded);

      final cropped = _centreCrop(upright, aspectRatio);
      final scaled = cropped.width > _maxEdge
          ? img.copyResize(cropped, width: _maxEdge)
          : cropped;

      return Uint8List.fromList(img.encodeJpg(scaled, quality: 88));
    } catch (error, stack) {
      debugPrint('Elapsa: card crop failed: $error\n$stack');
      return null;
    }
  }

  /// Crops to [region], given in normalised coordinates with a top-left
  /// origin, plus a margin.
  ///
  /// The fallback for a document the rectangle detector cannot find. Falling
  /// back to a card-shaped centre crop was actively destructive there: on an
  /// open passport, the machine-readable zone runs along the bottom of the
  /// page, and a centre crop at card proportions cuts it off — throwing away
  /// the one part of a passport that can be read with certainty.
  Future<Uint8List?> cropToRegion(String path, Rect region) async {
    try {
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final upright = img.bakeOrientation(decoded);

      // Text sits inside the document, not at its edge, so the box is opened
      // out to take in the page around it.
      const margin = 0.06;
      final left = ((region.left - margin) * upright.width).round();
      final top = ((region.top - margin) * upright.height).round();
      final right = ((region.right + margin) * upright.width).round();
      final bottom = ((region.bottom + margin) * upright.height).round();

      final x = left.clamp(0, upright.width - 1);
      final y = top.clamp(0, upright.height - 1);
      final width = (right.clamp(1, upright.width) - x);
      final height = (bottom.clamp(1, upright.height) - y);
      if (width < 16 || height < 16) return null;

      final cropped = img.copyCrop(
        upright,
        x: x,
        y: y,
        width: width,
        height: height,
      );
      final scaled = cropped.width > _maxEdge
          ? img.copyResize(cropped, width: _maxEdge)
          : cropped;

      return Uint8List.fromList(img.encodeJpg(scaled, quality: 88));
    } catch (error, stack) {
      debugPrint('Elapsa: region crop failed: $error\n$stack');
      return null;
    }
  }

  /// The largest rectangle of [aspectRatio] that fits inside [source],
  /// centred.
  static img.Image _centreCrop(img.Image source, double aspectRatio) {
    final sourceRatio = source.width / source.height;

    final int width;
    final int height;
    if (sourceRatio > aspectRatio) {
      // Source is wider than the card — trim the sides.
      height = source.height;
      width = (height * aspectRatio).round();
    } else {
      // Source is taller — trim top and bottom.
      width = source.width;
      height = (width / aspectRatio).round();
    }

    return img.copyCrop(
      source,
      x: ((source.width - width) / 2).round(),
      y: ((source.height - height) / 2).round(),
      width: width,
      height: height,
    );
  }
}
