import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:elapsa/services/frame_downsampler.dart';

/// A buffer where each pixel's value encodes where it came from, so a shear or
/// an off-by-one shows up as a wrong number rather than a subtly wrong picture.
Uint8List frame({
  required int width,
  required int height,
  required int bytesPerRow,
}) {
  final bytes = Uint8List(bytesPerRow * height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      bytes[y * bytesPerRow + x] = (y * 16 + x) % 256;
    }
  }
  return bytes;
}

void main() {
  group('padded rows', () {
    // Camera planes are padded for alignment: bytesPerRow exceeds the width.
    // Treating that padding as picture data shears the image diagonally, and
    // no rectangle detector will find anything in the result.
    const width = 8;
    const height = 4;
    const stride = 10;

    test('are repacked even when no shrinking is needed', () {
      final result = downsampleLuma(
        frame(width: width, height: height, bytesPerRow: stride),
        width: width,
        height: height,
        bytesPerRow: stride,
        targetWidth: 1000,
      );

      expect(result.width, width);
      expect(result.height, height);
      expect(result.bytes.length, width * height);

      // Row 1 must start at the value for (0, 1), not two bytes of padding in.
      expect(result.bytes[0], 0);
      expect(result.bytes[width], 16);
      expect(result.bytes[width * 2], 32);
    });

    test('are stepped over correctly when shrinking', () {
      final result = downsampleLuma(
        frame(width: width, height: height, bytesPerRow: stride),
        width: width,
        height: height,
        bytesPerRow: stride,
        targetWidth: 4,
      );

      expect(result.width, 4);
      expect(result.height, 2);
      // Every second pixel of every second row.
      expect(result.bytes, [0, 2, 4, 6, 32, 34, 36, 38]);
    });
  });

  test('a 720p plane shrinks to something worth sending', () {
    const width = 1280;
    const height = 720;
    final result = downsampleLuma(
      frame(width: width, height: height, bytesPerRow: width),
      width: width,
      height: height,
      bytesPerRow: width,
      targetWidth: 640,
    );

    expect(result.width, 640);
    expect(result.height, 360);
    // Under a quarter of the bytes, which is the whole point.
    expect(result.bytes.length, lessThan(width * height ~/ 3));
  });

  test('never reads past the end of the source', () {
    // The loop bounds are the thing most likely to be wrong, and getting them
    // wrong throws rather than misbehaving quietly — but only if exercised.
    for (final target in [64, 200, 420, 640, 4000]) {
      expect(
        () => downsampleLuma(
          frame(width: 1281, height: 721, bytesPerRow: 1288),
          width: 1281,
          height: 721,
          bytesPerRow: 1288,
          targetWidth: target,
        ),
        returnsNormally,
        reason: 'target $target',
      );
    }
  });

  test('output is always exactly width times height', () {
    for (final target in [100, 333, 640]) {
      final result = downsampleLuma(
        frame(width: 1280, height: 720, bytesPerRow: 1280),
        width: 1280,
        height: 720,
        bytesPerRow: 1280,
        targetWidth: target,
      );
      expect(result.bytes.length, result.width * result.height);
    }
  });
}
