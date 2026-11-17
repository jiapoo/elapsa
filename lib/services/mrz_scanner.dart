import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:elapsa/core/theme.dart';
import 'package:elapsa/domain/mrz.dart';
import 'package:elapsa/domain/document_type.dart';
import 'package:elapsa/domain/printed_fields.dart';
import 'package:elapsa/domain/script_detection.dart';
import 'package:elapsa/services/card_cropper.dart';
import 'package:elapsa/services/card_number_reader.dart';
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
    this._numbers = const CardNumberReader(),
  ]);

  final VisionChannel _vision;
  final CardCropper _cropper;
  final PrintedFieldParser _printed;
  final CardNumberReader _numbers;

  /// Processes one captured photo.
  ///
  /// Text is read from the **full-resolution original**, so the recogniser
  /// sees every pixel, while the stored face is the cropped card. Reading the
  /// crop instead would throw away detail the parsers depend on.
  /// The text as the recogniser returned it, and again as it was printed.
  ///
  /// Both, because neither is enough alone: the returned order is what carries
  /// captions next to their values, and the printed rows are what carry a card
  /// number as one number instead of as three pieces with other writing
  /// between them.
  static String _withRows(String text, Recognition read) {
    final rows = read.rows;
    return rows.trim().isEmpty || rows == text ? text : '$text\n$rows';
  }

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
  Future<Recognition> _readCrop(
    Uint8List cropped, {
    bool boost = false,
    int variant = 0,
    List<String>? languages,
  }) => _onDisk(
    cropped,
    (path) => _vision.recognize(
      path,
      boost: boost,
      variant: variant,
      languages: languages,
      // The crop is the document filling the picture: its writing is large
      // by construction, so nothing needs to be skipped as too small.
      minimumTextHeight: 0,
    ),
  ).then((read) => read ?? Recognition.empty);

  /// Runs [read] against [cropped] written to a temporary file, and deletes
  /// the file the moment it is done.
  Future<T?> _onDisk<T>(
    Uint8List cropped,
    Future<T> Function(String path) read,
  ) async {
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
      return await read(temp.path);
    } catch (error) {
      debugPrint('Elapsa: reading the crop failed: $error');
      return null;
    } finally {
      // The crop is a decrypted picture of someone's passport. It does not
      // stay on disk a moment longer than the read takes.
      if (temp != null && await temp.exists()) await temp.delete();
    }
  }

  /// The card number, read from the strip of the card it is printed on.
  ///
  /// This is the rescue for the failure the app keeps meeting: a bank card
  /// whose name, dates and holder all read and whose number does not. The
  /// number is embossed — the same colour as the card, visible only as a
  /// shadow — and on a painted card it runs straight across the artwork.
  ///
  /// Three things are done differently here from any pass over the whole card.
  /// The strip is read on its own and enlarged, so the figures are most of the
  /// picture rather than a twentieth of it. It is read with the Latin model
  /// only, because the Chinese one, given embossed figures over a painting,
  /// finds characters in them. And it is read many times, under every
  /// treatment at once, with the results put together by [CardNumberReader]
  /// rather than taken one at a time — each treatment loses a different part
  /// of the number, and between them they rarely lose all of it.
  /// Every way the number strip is looked at: -1 is the picture as it is,
  /// the rest are the native treatments.
  ///
  /// They are all here because each one is the only one that works on some
  /// card. Relief and flattening find a figure embossed in the card's own
  /// colour; 5 and 6 find silver foil stamped across a painting by its lack of
  /// colour, which no treatment that starts from brightness can do; 7 is the
  /// same for dark ink on colour; 8, the blue channel alone, turns the warm
  /// artwork most cards are printed with nearly black.
  static const _numberTreatments = [-1, 5, 0, 1, 2, 3, 4, 6, 7, 8];

  Future<({String? number, String seen})> _readNumber(
    Uint8List card,
    List<List<RecognisedLine>> already,
  ) async {
    final bands = numberBands(already.isEmpty ? const [] : already.first);
    final result = await _onDisk(card, (path) async {
      final passes = [...already];
      final seen = StringBuffer();
      String? number;

      // One strip at a time, every treatment at once. The treatments are
      // independent looks at a small picture and finish together; the strips
      // are alternatives, and the second is only worth its cost when the
      // first did not settle the number.
      for (final band in bands) {
        final looks = await Future.wait([
          for (final variant in _numberTreatments)
            _vision
                .recognize(
                  path,
                  region: band,
                  boost: variant >= 0,
                  variant: math.max(variant, 0),
                  languages: const ['en-US'],
                  minimumTextHeight: 0,
                )
                .then((look) => (variant: variant, look: look))
                .catchError(
                  (Object _) => (variant: variant, look: Recognition.empty),
                ),
        ]);

        for (final l in looks) {
          passes.add([for (final line in l.look.lines) line.placedIn(band)]);
          if (l.look.text.trim().isEmpty) continue;
          seen.write(
            '\n--- number strip ${band.top.toStringAsFixed(2)}'
            '-${band.bottom.toStringAsFixed(2)}, '
            '${l.variant < 0 ? 'plain' : 'treatment ${l.variant}'} ---\n'
            '${l.look.text}',
          );
        }

        number = _numbers.read(passes);
        if (number != null) break;
      }
      return (number: number, seen: seen.toString());
    });
    return result ?? (number: null, seen: '');
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
    // Only what is inside the document.
    //
    // The whole photograph is still read — it is what proves the crop kept the
    // writing — but the desk it was taken on has no business in the fields. A
    // card on a laptop gave up "return", "shift", "command" and "option", each
    // of which is a chance to be mistaken for a name.
    //
    // The picture is not read twice for this. The lines come back with the
    // boxes they were found in, so the ones outside the card are simply not
    // passed on.
    // Generously. The corners the crop was cut along come from the preview,
    // and the preview and the still do not always share a field of view — so
    // the region can sit a little off the card without anything being wrong
    // enough to notice. Trimming to it exactly threw away the bank's name,
    // which lives in the top corner where that error lands first.
    final region = cut?.bounds.inflate(0.06);
    final inside = region == null ? read.text : read.textInside(region);
    final text = inside.trim().isEmpty ? read.text : inside;

    if (kDebugMode) debugPrint('Elapsa OCR >>>\n$text\n<<< end OCR');

    // Read as printed as well as as returned.
    var reading = await _interpret(_withRows(text, read));
    var parsed = reading.mrz;

    // Whatever the card itself did not give up, the rest of the picture may.
    //
    // Filtering to the document is right for what it removes — a keyboard
    // under a card is not part of the card — but wrong if it also removes the
    // document. It cannot be told which it has done, so the whole picture
    // stays available to fill gaps and never to overrule: the worst case is a
    // field found in the wrong place, and the worst case of not doing it is a
    // field not found at all.
    if (text != read.text) {
      final whole = await _interpret(_withRows(read.text, read));
      parsed ??= whole.mrz;
      reading = (
        mrz: parsed,
        printed: reading.printed.mergedWith(whole.printed),
      );
    }

    // The crop is judged only once both passes have finished, so none of this
    // costs the user any time: the two still run side by side, and where the
    // writing was found is already known by the time it is needed.
    final trusted = _keeps(cut, read.lines, hasCode: parsed != null);
    final card = trusted ? cut!.bytes : await _fallbackFace(path, read.bounds);

    var printed = reading.printed;

    // Both, labelled. When a field is missing, the thing worth knowing is
    // whether the writing was never read or was read and then filtered away
    // as belonging to the desk — and one list cannot say which.
    final header = read.languages.isEmpty
        ? ''
        : 'read in ${read.languages.join(", ")}\n\n';

    var seen = text == read.text
        ? '$header$text'
        : '$header--- inside the document ---\n$text'
              '\n--- the whole picture ---\n${read.text}';

    // Read the document on its own as well as in its surroundings.
    //
    // A photograph taken without the guide is a photograph of a desk with a
    // passport somewhere in it, and there the small print is a fraction of the
    // frame. Inside the crop it is most of one. This is the difference between
    // a capture that fills the form in and one that appears to have read
    // nothing at all.
    //
    // Always, now, rather than only when the frame gave nothing.
    //
    // A photograph of a card is a photograph of whatever the card was lying
    // on. One diagnostic from a real scan came back with "return", "shift",
    // "command" and "option" in it — the card was on a laptop keyboard, and
    // the recogniser dutifully read the keyboard. Every one of those lines is
    // a chance to mistake something for a name or a number, and all of them
    // are competing for attention with the document.
    //
    // Inside the crop there is nothing but the document, and it fills the
    // frame, so its print is several times the size. Skipping that pass
    // whenever the whole picture happened to yield *an* expiry meant the best
    // reading available was the one most often not taken.
    // Read with the models this document turned out to need.
    //
    // The first pass had to guess, and it guessed Chinese, because that is the
    // order that loses least when nothing is known. It is known now: the
    // writing it found says which scripts are on the card, and a Korean
    // licence or a Japanese residence card is better read by its own model
    // than by a Chinese one doing its best. A card with no script but Latin on
    // it is read by the Latin model — which is also the better reader of its
    // figures.
    final detected = languagesForText(
      read.text,
      fallback: languages ?? const ['zh-Hans', 'zh-Hant', 'en-US'],
    );
    if (kDebugMode) debugPrint('Elapsa: languages for the crop: $detected');

    Recognition? cropRead;
    if (card != null) {
      final look = await _readCrop(card, languages: detected);
      cropRead = look;
      final closer = look.text;
      if (closer.trim().isNotEmpty) {
        reading = await _interpret(_withRows(closer, look));

        // Which reading wins turns on whether the crop can be trusted, and
        // that is a question the frame answers.
        //
        // A trusted crop is the document, filling the picture, with nothing
        // else in it — so its reading is better in every way and should win.
        // An untrusted one is a rectangle the app is unsure of, and a crop
        // that clipped a line has a confident wrong answer where the whole
        // frame had a right one; there it may only fill gaps.
        parsed = trusted ? (reading.mrz ?? parsed) : (parsed ?? reading.mrz);
        printed = trusted
            ? reading.printed.mergedWith(printed)
            : printed.mergedWith(reading.printed);
        seen = '$text\n--- crop ---\n$closer';
      }
    }

    // A document whose number did not read gets a second look, boosted.
    //
    // This is the failure the app keeps hitting on a bank card: the bank's
    // name, the dates and the holder all come back correctly and the number —
    // the one field that identifies the card — comes back as nothing. Those
    // fields are flat print; the number is embossed, and has almost no tonal
    // contrast for a recogniser to find.
    //
    // Not for a document that has said what it is and is not a card. A
    // passport or an identity card has its number already, or a number of a
    // shape this cannot read.
    final mayBeCard =
        printed.type == null || printed.type == DocumentType.bankCard;
    if (parsed == null && printed.documentNumber == null && mayBeCard) {
      // First, the readings already made, put together. Every line of the
      // crop came back with its runners-up, and the checksum can often pick
      // the right one out of those without another look at the picture.
      final already = [if (cropRead != null) cropRead.lines];
      var number = _numbers.read(already);

      // Then the strip the number is printed on, read closely, many ways.
      if (number == null && card != null) {
        final strip = await _readNumber(card, already);
        number = strip.number;
        seen = '$seen${strip.seen}';
      }

      // And last, the old rescue: the whole card under each treatment, read
      // with the document's own languages, parsed one look at a time.
      if (number == null) {
        for (final attempt in [
          if (card != null)
            for (var variant = 0; variant < 9; variant++)
              (
                'crop, treatment $variant',
                () => _readCrop(
                  card,
                  boost: true,
                  variant: variant,
                  languages: detected,
                ),
              ),
          (
            'whole frame, treatment 0',
            () => _vision.recognize(path, boost: true, languages: languages),
          ),
        ]) {
          final look = await attempt.$2();
          if (look.text.trim().isEmpty) continue;
          seen = '$seen\n--- ${attempt.$1} ---\n${look.text}';
          printed = printed.mergedWith(
            _printed.parse(_withRows(look.text, look)),
          );
          if (printed.documentNumber != null) break;
        }
      }

      if (number != null) {
        printed = printed.mergedWith(
          PrintedFields(documentNumber: number, type: DocumentType.bankCard),
        );
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
  /// A line shaped like a machine-readable zone: nothing but capitals, digits
  /// and chevrons, and far too long to be anything else on a document.
  static final _codeLine = RegExp(r'^[A-Z0-9<]{25,}$');

  static bool _keeps(
    CardCut? cut,
    List<RecognisedLine> lines, {
    required bool hasCode,
  }) {
    if (cut == null) return false;
    if (!hasCode) return true;

    // The machine-readable lines specifically, not all the writing there is.
    //
    // Measuring against every line found was fine until a photograph turned up
    // with a laptop keyboard in it: the union of all text then covers half the
    // desk, no crop can contain it, and a perfectly good cut of a passport
    // gets thrown away for failing to include the space bar. What the check
    // was ever for is narrower than that — has the crop cut off the code? — so
    // it now asks exactly that.
    final code = [
      for (final line in lines)
        if (_codeLine.hasMatch(line.text.replaceAll(' ', ''))) line,
    ];
    if (code.isEmpty) return true;

    return code.every((line) => cut.bounds.contains(line.box.center));
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
