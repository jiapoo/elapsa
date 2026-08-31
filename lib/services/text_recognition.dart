import 'package:flutter/services.dart';

/// On-device text recognition, implemented natively on each platform.
///
/// iOS uses Apple's Vision framework and Android uses ML Kit. Both run entirely
/// on the device — no image ever leaves the phone, which is the whole promise
/// of the app and not something to delegate to a service.
///
/// This is a platform channel rather than a Dart package on purpose: the ML Kit
/// Flutter plugin drags in an iOS SDK built as a legacy fat framework, whose
/// arm64 slice is device-only. That forces the entire app to x86_64 on the
/// simulator and makes it uninstallable on Apple Silicon. Vision has no such
/// problem, is a system framework so costs nothing in app size, and recognises
/// Chinese better than ML Kit's Latin model does.
class TextRecognition {
  const TextRecognition();

  static const _channel = MethodChannel('cc.elapsa/text_recognition');

  /// Returns every line of text found in the image at [path], newline
  /// separated, or an empty string if there is none.
  ///
  /// Recognition is tuned for machine-readable zones: accuracy over speed, and
  /// no language correction, because an MRZ is not words and autocorrecting it
  /// towards a dictionary destroys the check digits.
  Future<String> recognizeFile(String path) async {
    final text = await _channel.invokeMethod<String>('recognize', {
      'path': path,
    });
    return text ?? '';
  }
}
