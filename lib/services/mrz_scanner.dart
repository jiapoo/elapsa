import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';

import 'package:elapsa/core/theme.dart';
import 'package:elapsa/domain/mrz.dart';
import 'package:elapsa/domain/document_type.dart';
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
    final (read, cut) = await (
      _vision.recognize(path),
      _vision.extractCard(path, quad: quad),
    ).wait;
    final text = read.text;

    // The crop is decided only once both have finished, so the fallback costs
    // nothing in the ordinary case: the two passes still run side by side, and
    // where the writing was found is already known by the time it is needed.
    final card = cut ?? await _fallbackFace(path, read.bounds);
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

    var printed = _printed.parse(text);
    var seen = text;

    // A card whose number did not read gets a second look.
    //
    // This is the exact failure the app kept hitting: the bank's name, the
    // dates and the holder all come back correctly, and the number — the one
    // field that identifies the card — comes back as nothing. Those fields are
    // flat print; the number is embossed, and has no tonal contrast for a
    // recogniser to find. The second pass manufactures some.
    //
    // Only in that case. The treatment that rescues raised figures blooms fine
    // print, so running it always would cost the fields that already work, and
    // running it at all costs a second full-resolution pass.
    if (printed.type == DocumentType.bankCard &&
        printed.documentNumber == null) {
      final boosted = (await _vision.recognize(path, boost: true)).text;
      if (boosted.trim().isNotEmpty) {
        seen = '$text\n$boosted';
        printed = printed.mergedWith(_printed.parse(boosted));
      }
    }

    return ScanResult(
      mrz: parsed,
      printed: printed,
      cardImage: card,
      rawText: seen,
    );
  }

  /// What to keep when the document would not square up.
  ///
  /// Not everything Elapsa tracks is a rectangle with four findable corners.
  /// An open passport is the clear case: the data page runs into the facing
  /// page across the fold and the paper curves away from flat, so there is no
  /// outline to lock on to — and the centre crop this used to fall back to was
  /// worse than useless there. A card-shaped window taken out of the middle of
  /// an open passport cuts off the machine-readable zone along the bottom of
  /// the page, which is the one part of a passport that can be read with
  /// certainty.
  ///
  /// So it falls back to the writing instead. Where the text is, the document
  /// is; and a crop around all of it keeps the page whatever shape the page
  /// turned out to be.
  Future<Uint8List?> _fallbackFace(String path, Rect? textBounds) async {
    if (textBounds != null) {
      final region = await _cropper.cropToRegion(path, textBounds);
      if (region != null) return region;
    }
    // Nothing read either: the centre of the frame is the last guess left.
    return _cropper.cropToCard(path, aspectRatio: kCardAspectRatio);
  }
}
