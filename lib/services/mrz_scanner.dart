import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

  /// Where in the photograph the document was cut from, when it was cut from
  /// somewhere in particular.
  ///
  /// Handed back so the crop screen can open on the cut that was made rather
  /// than on a guess — adjusting a good crop by a few millimetres is a
  /// different job from drawing one from scratch, and only one of them is what
  /// somebody who tapped an existing picture is there to do.
  final Rect? region;

  /// Whether the crop came from a rectangle the detector actually found and
  /// that survived checking, rather than from a fallback.
  ///
  /// The scanner offers the corners to the user by hand when this is false —
  /// which is the honest moment to ask, because it is exactly when the app
  /// has run out of ideas of its own.
  final bool croppedConfidently;

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
    this.croppedConfidently = false,
    this.region,
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
  /// What one pass of reading produced.
  Future<({MrzResult? mrz, PrintedFields printed})> _interpret(
    String text,
  ) async {
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
    return (mrz: parsed, printed: _printed.parse(text));
  }

  /// Reads the cropped document itself, rather than the photo it came out of.
  ///
  /// Worth a second pass whenever the first found nothing. A recogniser
  /// measures text against the height of the whole image, so the same
  /// machine-readable zone that is a couple of hundredths of a photograph of a
  /// desk is a tenth of the crop — and small print that fell under the floor
  /// in one clears it comfortably in the other. It is also the whole reason a
  /// document held at arm's length reads worse than the same document filling
  /// the frame.
  Future<String> _readCrop(
    Uint8List cropped, {
    bool boost = false,
    int variant = 0,
    List<String>? languages,
  }) async {
    File? temp;
    try {
      final dir = await getTemporaryDirectory();
      temp = File(
        p.join(
          dir.path,
          'elapsa-crop-${DateTime.now().microsecondsSinceEpoch}.jpg',
        ),
      );
      await temp.writeAsBytes(cropped);
      return (await _vision.recognize(
        temp.path,
        boost: boost,
        variant: variant,
      )).text;
    } catch (error) {
      debugPrint('Elapsa: reading the crop failed: $error');
      return '';
    } finally {
      // The crop is a decrypted picture of someone's passport. It does not
      // stay on disk a moment longer than the read takes.
      if (temp != null && await temp.exists()) await temp.delete();
    }
  }

  /// Re-cuts a photo along corners placed by hand, and reads it again.
  ///
  /// Reading again is the point. Placing the corners is new information about
  /// where the document is, and the fields ought to be filled from the better
  /// framing rather than left as whatever the first guess produced.
  Future<ScanResult> recut(
    String path,
    CardQuad quad, {
    List<String>? languages,
  }) => scanFile(path, quad: quad, byHand: true, languages: languages);

  /// Reads one captured photo.
  ///
  /// [byHand] says the corners in [quad] were placed by a person rather than
  /// found by the detector. That changes what is worth reading: a hand-placed
  /// crop is a statement about where the document is, and the app should take
  /// it as one — so the crop is read *as well as* the frame, always, instead
  /// of only as a rescue when the frame yielded nothing.
  Future<ScanResult> scanFile(
    String path, {
    CardQuad? quad,
    bool byHand = false,

    /// The scripts to try, most likely first. Comes from the app's own
    /// language setting: the user has already said which language they read
    /// in, and their documents are overwhelmingly likely to be printed in it.
    List<String>? languages,
  }) async {
    // Reading the text and cutting the card are independent passes over the
    // same photo, and each is a full Vision request. Run together they finish
    // in about the time the slower one takes; run in series the user waits for
    // both.
    final (read, cut) = await (
      _vision.recognize(path, languages: languages),
      _vision.extractCard(path, quad: quad, byHand: byHand),
    ).wait;
    final text = read.text;

    if (kDebugMode) debugPrint('Elapsa OCR >>>\n$text\n<<< end OCR');

    var reading = await _interpret(text);
    var parsed = reading.mrz;

    // The crop is judged only once both passes have finished, so none of this
    // costs the user any time: the two still run side by side, and where the
    // writing was found is already known by the time it is needed.
    final trusted = _keeps(cut, read.bounds, hasCode: parsed != null);
    final card = trusted ? cut!.bytes : await _fallbackFace(path, read.bounds);

    var printed = reading.printed;
    var seen = text;

    // Read the document on its own as well as in its surroundings.
    //
    // A photograph taken without the guide is a photograph of a desk with a
    // passport somewhere in it, and there the small print is a fraction of the
    // frame. Inside the crop it is most of one. This is the difference between
    // a capture that fills the form in and one that appears to have read
    // nothing at all.
    //
    // Always when the corners were placed by hand — that is the whole point of
    // having placed them — and otherwise only when the frame gave nothing
    // worth having, since it costs another full pass.
    final worthACloserLook =
        byHand ||
        (parsed == null && printed.expiryDate == null && !printed.neverExpires);
    if (worthACloserLook && card != null) {
      final closer = await _readCrop(card, languages: languages);
      if (closer.trim().isNotEmpty) {
        reading = await _interpret(closer);
        // Gaps only. The closer look used to win outright wherever the two
        // disagreed, on the reasoning that it was taken of the document rather
        // than of the room around it — but it is also taken of a *crop*, and a
        // crop that clipped a line has a confident wrong answer where the
        // whole frame had a right one. Filling what is missing is the part
        // that was ever worth having.
        parsed ??= reading.mrz;
        printed = printed.mergedWith(reading.printed);
        seen = '$text\n--- crop ---\n$closer';
      }
    }

    // A document whose number did not read gets a second look, boosted.
    //
    // This is the failure the app keeps hitting on a bank card: the bank's
    // name, the dates and the holder all come back correctly and the number —
    // the one field that identifies the card — comes back as nothing. Those
    // fields are flat print; the number is embossed, and has almost no tonal
    // contrast for a recogniser to find. The boost manufactures some.
    //
    // The *crop* is boosted first, and that is the part that was missing: a
    // recogniser measures text against the height of the whole image, so
    // embossed figures on a card that fills a third of a photograph are a
    // third the size they are on the card alone. Boosting the frame and not
    // the card was doing the harder half of the job.
    //
    // Widened from "looks like a bank card" to "has no number yet", because
    // the old test needed the bank's name to have been read — and a photo that
    // lost the number is exactly the kind that also loses the wording.
    if (parsed == null && printed.documentNumber == null) {
      // Both treatments, on the card first and the whole frame after. They
      // fail in opposite conditions — one cannot cope with a pale digit on a
      // pale card, the other cannot cope with a dark one — so trying a single
      // treatment was a coin toss dressed up as a rescue.
      for (final attempt in [
        if (card != null)
          ('crop flattened', () => _readCrop(card, boost: true)),
        if (card != null)
          ('crop hardened', () => _readCrop(card, boost: true, variant: 1)),
        (
          'frame flattened',
          () async => (await _vision.recognize(
            path,
            boost: true,
            languages: languages,
          )).text,
        ),
        (
          'frame hardened',
          () async =>
              (await _vision.recognize(path, boost: true, variant: 1)).text,
        ),
      ]) {
        final read = await attempt.$2();
        if (read.trim().isEmpty) continue;
        seen = '$seen\n--- ${attempt.$1} ---\n$read';
        printed = printed.mergedWith(_printed.parse(read));
        if (printed.documentNumber != null) break;
      }
    }

    return ScanResult(
      mrz: parsed,
      printed: printed,
      cardImage: card,
      rawText: seen,
      croppedConfidently: trusted,
      region: trusted ? cut?.bounds : null,
    );
  }

  /// Whether the crop can be trusted to have kept what matters.
  ///
  /// A detector finds *a* rectangle, not necessarily the right one. On a
  /// passport the cleanest edges belong to the tinted panel behind the data,
  /// not to the page, so the crop came out framing the data page neatly with
  /// the machine-readable zone left outside it — the one part of a passport
  /// that carries its own check digits, thrown away.
  ///
  /// So a crop is checked against the writing: it has to contain essentially
  /// all of the text that was read, or it is not the document.
  ///
  /// Only for a document that turned out to have a machine-readable zone. A
  /// card photographed on a desk covered in other paper has text sprawling
  /// well past its own edges, and demanding the crop swallow all of that would
  /// throw away a perfectly good card face in favour of the whole tabletop.
  static bool _keeps(CardCut? cut, Rect? text, {required bool hasCode}) {
    if (cut == null) return false;
    if (!hasCode || text == null || text.isEmpty) return true;

    final kept = cut.bounds.intersect(text);
    if (kept.isEmpty) return false;

    final covered = (kept.width * kept.height) / (text.width * text.height);
    return covered >= 0.95;
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
