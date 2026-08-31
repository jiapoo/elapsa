import Flutter
import UIKit
import Vision

/// On-device OCR backed by Apple's Vision framework.
///
/// Tuned for machine-readable zones rather than prose:
///
///   * `.accurate` — the MRZ is small, dense and check-digit protected, so a
///     slower, better read is always the right trade.
///   * language correction **off** — an MRZ is not words. Correcting
///     `L898902C36` towards a dictionary is exactly how check digits break.
///   * Latin plus Chinese — the MRZ itself is always Latin by ICAO definition,
///     but the same recogniser reads the printed face of Chinese documents.
enum TextRecognitionHandler {

  /// Registers against the engine's plugin registrar rather than a view
  /// controller.
  ///
  /// This app uses the scene lifecycle, so `window` is still nil when
  /// `didFinishLaunchingWithOptions` runs — reaching for the root view
  /// controller there silently registers nothing, and every call from Dart
  /// then fails as a missing plugin.
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "cc.elapsa/text_recognition",
      binaryMessenger: registrar.messenger()
    )

    channel.setMethodCallHandler { call, result in
      guard call.method == "recognize" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard
        let args = call.arguments as? [String: Any],
        let path = args["path"] as? String
      else {
        result(FlutterError(
          code: "bad_arguments",
          message: "recognize requires a file path",
          details: nil
        ))
        return
      }

      recognize(path: path, result: result)
    }
  }

  private static func recognize(path: String, result: @escaping FlutterResult) {
    guard
      let image = UIImage(contentsOfFile: path),
      let cgImage = image.cgImage
    else {
      result(FlutterError(
        code: "unreadable_image",
        message: "Could not open the image at \(path)",
        details: nil
      ))
      return
    }

    // Vision reasons about an upright image, so the photo's EXIF orientation
    // has to be handed over explicitly — otherwise a picture taken in portrait
    // is analysed sideways and nothing is found.
    let orientation = cgOrientation(from: image.imageOrientation)

    let request = VNRecognizeTextRequest { request, error in
      if let error = error {
        result(FlutterError(
          code: "recognition_failed",
          message: error.localizedDescription,
          details: nil
        ))
        return
      }

      let observations = request.results as? [VNRecognizedTextObservation] ?? []
      let lines = observations.compactMap { $0.topCandidates(1).first?.string }
      result(lines.joined(separator: "\n"))
    }

    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false
    request.recognitionLanguages = supportedLanguages(for: request)

    // Off the main thread: .accurate recognition on a full-resolution photo
    // takes long enough to drop frames if it runs on the platform thread.
    DispatchQueue.global(qos: .userInitiated).async {
      let handler = VNImageRequestHandler(
        cgImage: cgImage,
        orientation: orientation,
        options: [:]
      )
      do {
        try handler.perform([request])
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "recognition_failed",
            message: error.localizedDescription,
            details: nil
          ))
        }
      }
    }
  }

  /// Narrows the languages we want to the ones this OS actually ships.
  ///
  /// Which iOS release added which script has moved around, and asking Vision
  /// for a language it does not have throws at perform time. Filtering against
  /// what the device reports keeps a Chinese-capable build working on older
  /// systems, where it simply falls back to Latin — which is all an MRZ ever
  /// needs, since ICAO defines it as `A-Z`, `0-9` and `<`.
  private static func supportedLanguages(
    for request: VNRecognizeTextRequest
  ) -> [String] {
    let wanted = ["en-US", "zh-Hans", "zh-Hant"]
    guard let available = try? request.supportedRecognitionLanguages() else {
      return ["en-US"]
    }
    let usable = wanted.filter { available.contains($0) }
    return usable.isEmpty ? ["en-US"] : usable
  }

  private static func cgOrientation(
    from orientation: UIImage.Orientation
  ) -> CGImagePropertyOrientation {
    switch orientation {
    case .up:            return .up
    case .down:          return .down
    case .left:          return .left
    case .right:         return .right
    case .upMirrored:    return .upMirrored
    case .downMirrored:  return .downMirrored
    case .leftMirrored:  return .leftMirrored
    case .rightMirrored: return .rightMirrored
    @unknown default:    return .up
    }
  }
}
