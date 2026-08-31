import 'package:flutter/foundation.dart';

import 'package:elapsa/core/theme.dart';
import 'package:elapsa/domain/mrz.dart';
import 'package:elapsa/services/card_cropper.dart';
import 'package:elapsa/services/vision_channel.dart';

/// What reading a document produced.
///
/// The card image is separate from the parse result on purpose: a picture the
/// user framed is worth keeping even when the code on it could not be read.
class ScanResult {
  /// Null when no machine-readable zone was found at all.
  final MrzResult? mrz;

  /// The flattened card face. Null only if the photo could not be decoded.
  final Uint8List? cardImage;

  const ScanResult({this.mrz, this.cardImage});

  /// True when a code was found *and* every check digit agreed.
  bool get isTrustworthy => mrz?.isValid ?? false;

  /// A code was found but could not be read cleanly — worth telling the user,
  /// because the advice differs from "no code at all".
  bool get isUnreadable => mrz != null && !mrz!.isValid;
}

/// Reads a document: flattens the card, then reads the code off it.
///
/// The OCR and card detection are native — Apple Vision on iOS — behind
/// [VisionChannel]. Everything above that line is pure Dart and unit-tested,
/// which is why the parser could be finished and verified long before either
/// platform's camera existed.
class MrzScanner {
  const MrzScanner([
    this._vision = const VisionChannel(),
    this._cropper = const CardCropper(),
  ]);

  final VisionChannel _vision;
  final CardCropper _cropper;

  /// Processes one captured photo.
  ///
  /// The order matters. Text is read from the **full-resolution original**, so
  /// the recogniser sees every pixel of the machine-readable zone, while the
  /// stored face is the flattened card. Reading the cropped version instead
  /// would throw away detail the parser depends on.
  Future<ScanResult> scanFile(String path) async {
    final text = await _vision.recognize(path);
    if (kDebugMode) debugPrint('Elapsa OCR >>>\n$text\n<<< end OCR');

    final card = await _cardFace(path);

    MrzResult? parsed;
    if (text.trim().isNotEmpty) {
      try {
        parsed = MrzParser.parse(text);
      } on MrzException {
        // No MRZ in this image — expected for the back of a card, or a page
        // that simply has no code on it.
        parsed = null;
      }
    }

    return ScanResult(mrz: parsed, cardImage: card);
  }

  /// The flattened card, falling back to a centre crop.
  ///
  /// Perspective correction needs Vision to actually find a rectangle. When it
  /// cannot — a document flat on a same-coloured desk, say — a centre crop at
  /// the card aspect still produces something usable rather than nothing.
  Future<Uint8List?> _cardFace(String path) async {
    final flattened = await _vision.extractCard(path);
    if (flattened != null) return flattened;
    return _cropper.cropToCard(path, aspectRatio: kCardAspectRatio);
  }
}
