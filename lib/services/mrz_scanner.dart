import 'package:flutter/foundation.dart';

import 'package:elapsa/core/theme.dart';
import 'package:elapsa/domain/mrz.dart';
import 'package:elapsa/domain/printed_fields.dart';
import 'package:elapsa/services/card_cropper.dart';
import 'package:elapsa/services/vision_channel.dart';

/// What reading a document produced.
///
/// The card image is separate from the parsed data on purpose: a picture the
/// user framed is worth keeping even when nothing legible could be read off
/// it.
class ScanResult {
  /// Set only when the document carries a machine-readable zone.
  final MrzResult? mrz;

  /// Read off the printed face. Most of the world's documents have no MRZ —
  /// a Chinese 居民身份证, a driving licence, an insurance card — and print
  /// their expiry in plain sight instead.
  final PrintedFields printed;

  /// The card face, rotated upright and cropped. Null only if the photo could
  /// not be decoded.
  final Uint8List? cardImage;

  /// Everything the recogniser read, verbatim.
  ///
  /// Kept so the app can show it back when a field comes up empty. That single
  /// screen separates "the camera never read it" from "the parser did not
  /// understand it", which is otherwise unanswerable from the outside.
  final String rawText;

  const ScanResult({
    this.mrz,
    this.printed = PrintedFields.empty,
    this.cardImage,
    this.rawText = '',
  });

  /// True when an MRZ was found *and* every check digit agreed.
  bool get hasTrustedCode => mrz?.isValid ?? false;

  /// An MRZ was found but could not be read cleanly — worth telling the user,
  /// because the advice differs from "no code at all".
  bool get isUnreadableCode => mrz != null && !mrz!.isValid;

  /// Whether anything usable came back, from either route.
  bool get foundAnything => hasTrustedCode || !printed.isEmpty;
}

/// Reads a document: cuts out the card, then reads whatever it can off it.
///
/// Two routes, tried in that order of trust. The machine-readable zone is
/// protected by check digits, so a valid parse is near-certain. Printed text
/// has no such guarantee, which is why the parser behind it refuses to guess
/// (see [PrintedFieldParser]).
///
/// Both run on the same recognised text, so a passport gets its MRZ read and
/// an ID card gets its 有效期限 read, with no second pass over the image.
class MrzScanner {
  const MrzScanner([
    this._vision = const VisionChannel(),
    this._cropper = const CardCropper(),
    this._printed = const PrintedFieldParser(),
  ]);

  final VisionChannel _vision;
  final CardCropper _cropper;
  final PrintedFieldParser _printed;

  /// Processes one captured photo.
  ///
  /// Text is read from the **full-resolution original**, so the recogniser
  /// sees every pixel, while the stored face is the cropped card. Reading the
  /// crop instead would throw away detail the parsers depend on.
  Future<ScanResult> scanFile(String path, {CardQuad? quad}) async {
    // Reading the text and cutting the card are independent passes over the
    // same photo, and each is a full Vision request. Run together they finish
    // in about the time the slower one takes; run in series the user waits for
    // both.
    final (text, card) = await (
      _vision.recognize(path),
      _cardFace(path, quad),
    ).wait;
    if (kDebugMode) debugPrint('Elapsa OCR >>>\n$text\n<<< end OCR');

    MrzResult? parsed;
    if (text.trim().isNotEmpty) {
      try {
        parsed = MrzParser.parse(text);
      } on MrzException {
        // No MRZ in this image — the normal case for an ID card, and for the
        // back of almost anything.
        parsed = null;
      }
    }

    return ScanResult(
      mrz: parsed,
      printed: _printed.parse(text),
      cardImage: card,
      rawText: text,
    );
  }

  /// The card, cut out of the photo.
  ///
  /// Uses [quad] — the corners the scanner had locked on when the shutter
  /// fired — so the saved card is the one the user framed. Falls back to
  /// detecting afresh, then to a centre crop, when there is no quad or Vision
  /// cannot find a rectangle. Something usable beats nothing.
  Future<Uint8List?> _cardFace(String path, CardQuad? quad) async {
    final cut = await _vision.extractCard(path, quad: quad);
    if (cut != null) return cut;
    return _cropper.cropToCard(path, aspectRatio: kCardAspectRatio);
  }
}
