import 'package:flutter/foundation.dart';

import 'package:elapsa/domain/mrz.dart';
import 'package:elapsa/services/text_recognition.dart';

/// Outcome of trying to read a document.
sealed class ScanOutcome {
  const ScanOutcome();
}

/// A machine-readable zone was found and every check digit agreed.
class ScanSucceeded extends ScanOutcome {
  final MrzResult result;
  const ScanSucceeded(this.result);
}

/// An MRZ was found but its check digits disagreed.
///
/// Kept distinct from [ScanFoundNothing] because it calls for different advice:
/// the user framed the document correctly and the photo was simply too poor to
/// read, so "try again with less glare" is useful where "line it up properly"
/// would be wrong.
class ScanUnreadable extends ScanOutcome {
  final MrzResult partial;
  const ScanUnreadable(this.partial);
}

/// No MRZ-shaped text in the image at all.
class ScanFoundNothing extends ScanOutcome {
  const ScanFoundNothing();
}

/// Reads the machine-readable zone off a photo of a document.
///
/// The OCR itself is native — Vision on iOS, ML Kit on Android — behind
/// [TextRecognition]. Everything above that line is pure Dart and unit-tested,
/// which is why the parser could be finished and verified long before either
/// platform's camera existed.
class MrzScanner {
  const MrzScanner([this._ocr = const TextRecognition()]);

  final TextRecognition _ocr;

  Future<ScanOutcome> scanFile(String path) async {
    final text = await _ocr.recognizeFile(path);
    if (kDebugMode) {
      debugPrint('Elapsa OCR >>>\n$text\n<<< end OCR');
    }
    if (text.trim().isEmpty) return const ScanFoundNothing();

    try {
      final result = MrzParser.parse(text);
      return result.isValid ? ScanSucceeded(result) : ScanUnreadable(result);
    } on MrzException {
      return const ScanFoundNothing();
    }
  }
}
