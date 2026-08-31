import CoreImage
import Flutter
import UIKit
import Vision

/// On-device Vision work: finding the card in the frame, flattening it, and
/// reading it.
///
/// All three run entirely on the device. Nothing is uploaded, which is the
/// whole promise of the app and not something to delegate to a service.
enum VisionHandler {

  private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "cc.elapsa/vision",
      binaryMessenger: registrar.messenger()
    )

    channel.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any] ?? [:]

      switch call.method {
      case "recognize":
        guard let path = args["path"] as? String else {
          result(badArguments("recognize needs a path")); return
        }
        recognize(path: path, result: result)

      case "detectCard":
        guard
          let data = args["bytes"] as? FlutterStandardTypedData,
          let width = args["width"] as? Int,
          let height = args["height"] as? Int,
          let bytesPerRow = args["bytesPerRow"] as? Int
        else {
          result(badArguments("detectCard needs bytes, width, height, bytesPerRow")); return
        }
        detectCard(
          luma: data.data, width: width, height: height,
          bytesPerRow: bytesPerRow, result: result
        )

      case "extractCard":
        guard let path = args["path"] as? String else {
          result(badArguments("extractCard needs a path")); return
        }
        extractCard(path: path, result: result)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func badArguments(_ message: String) -> FlutterError {
    FlutterError(code: "bad_arguments", message: message, details: nil)
  }

  // ------------------------------------------------------------ recognition

  /// Reads text from an image file.
  ///
  /// Tuned for machine-readable zones rather than prose: accurate over fast,
  /// and language correction **off**, because an MRZ is not words and nudging
  /// `L898902C36` towards a dictionary is exactly how check digits break.
  private static func recognize(path: String, result: @escaping FlutterResult) {
    guard
      let image = UIImage(contentsOfFile: path),
      let cgImage = image.cgImage
    else {
      result(FlutterError(code: "unreadable_image", message: "Could not open \(path)", details: nil))
      return
    }

    let request = VNRecognizeTextRequest { request, error in
      if let error = error {
        result(FlutterError(code: "recognition_failed", message: error.localizedDescription, details: nil))
        return
      }
      let observations = request.results as? [VNRecognizedTextObservation] ?? []
      result(observations.compactMap { $0.topCandidates(1).first?.string }
        .joined(separator: "\n"))
    }

    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false
    request.recognitionLanguages = supportedLanguages(for: request)

    perform([request], on: cgImage,
            orientation: cgOrientation(from: image.imageOrientation),
            onFailure: result)
  }

  /// Narrows the languages we want to the ones this OS actually ships.
  ///
  /// Asking Vision for a language it does not have throws at perform time, and
  /// which release added which script has moved around. On an older system
  /// this quietly falls back to Latin, which is all an MRZ ever needs.
  private static func supportedLanguages(for request: VNRecognizeTextRequest) -> [String] {
    let wanted = ["en-US", "zh-Hans", "zh-Hant"]
    guard let available = try? request.supportedRecognitionLanguages() else {
      return ["en-US"]
    }
    let usable = wanted.filter { available.contains($0) }
    return usable.isEmpty ? ["en-US"] : usable
  }

  // --------------------------------------------------------------- detection

  /// Finds a card-shaped rectangle in a live preview frame.
  ///
  /// Takes only the luminance plane. Rectangle detection does not need colour,
  /// and sending one byte per pixel instead of four keeps a 30fps preview from
  /// saturating the platform channel.
  ///
  /// Returns the four corners normalised 0-1 in Vision's coordinate space
  /// (origin bottom-left), or nil when nothing card-like is in frame.
  private static func detectCard(
    luma: Data, width: Int, height: Int, bytesPerRow: Int,
    result: @escaping FlutterResult
  ) {
    var pixels = [UInt8](luma)
    guard let provider = CGDataProvider(data: Data(pixels) as CFData) else {
      result(nil); return
    }
    pixels.removeAll()

    guard let cgImage = CGImage(
      width: width,
      height: height,
      bitsPerComponent: 8,
      bitsPerPixel: 8,
      bytesPerRow: bytesPerRow,
      space: CGColorSpaceCreateDeviceGray(),
      bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
      provider: provider,
      decode: nil,
      shouldInterpolate: false,
      intent: .defaultIntent
    ) else {
      result(nil); return
    }

    let request = makeRectangleRequest { observation in
      result(observation.map(corners))
    }

    perform([request], on: cgImage, orientation: .up) { _ in result(nil) }
  }

  /// Detects the card in a full-resolution capture and flattens it.
  ///
  /// Perspective correction is what separates this from a centre crop: a card
  /// photographed at an angle comes back square-on, the way it would look on a
  /// scanner bed. Returns nil when no rectangle is found, and the caller falls
  /// back to a plain centre crop.
  private static func extractCard(path: String, result: @escaping FlutterResult) {
    guard let image = UIImage(contentsOfFile: path), let cgImage = image.cgImage else {
      result(nil); return
    }

    let orientation = cgOrientation(from: image.imageOrientation)
    let ciImage = CIImage(cgImage: cgImage).oriented(orientation)
    let extent = ciImage.extent

    let request = makeRectangleRequest { observation in
      guard let observation = observation else { result(nil); return }

      // Vision reports normalised points; Core Image wants them in image
      // space. Both use a bottom-left origin, so this is a plain scale.
      func point(_ p: CGPoint) -> CIVector {
        CIVector(x: extent.origin.x + p.x * extent.width,
                 y: extent.origin.y + p.y * extent.height)
      }

      guard let filter = CIFilter(name: "CIPerspectiveCorrection") else {
        result(nil); return
      }
      filter.setValue(ciImage, forKey: kCIInputImageKey)
      filter.setValue(point(observation.topLeft), forKey: "inputTopLeft")
      filter.setValue(point(observation.topRight), forKey: "inputTopRight")
      filter.setValue(point(observation.bottomLeft), forKey: "inputBottomLeft")
      filter.setValue(point(observation.bottomRight), forKey: "inputBottomRight")

      guard
        let output = filter.outputImage,
        let jpeg = ciContext.jpegRepresentation(
          of: output,
          colorSpace: CGColorSpaceCreateDeviceRGB(),
          options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.9]
        )
      else {
        result(nil); return
      }

      result(FlutterStandardTypedData(bytes: jpeg))
    }

    perform([request], on: cgImage, orientation: orientation) { _ in result(nil) }
  }

  private static func makeRectangleRequest(
    _ completion: @escaping (VNRectangleObservation?) -> Void
  ) -> VNDetectRectanglesRequest {
    let request = VNDetectRectanglesRequest { request, _ in
      let found = (request.results as? [VNRectangleObservation])?.first
      completion(found)
    }

    // Vision expresses aspect ratio as short side over long side. An ID-1 card
    // is 0.63 and a passport data page about 0.70, so this window covers the
    // documents we track while rejecting the long thin shapes that windowsills
    // and table edges produce.
    request.minimumAspectRatio = 0.45
    request.maximumAspectRatio = 0.95
    request.minimumSize = 0.25
    request.minimumConfidence = 0.7
    request.maximumObservations = 1
    // How far from square the corners may be. Loose enough for a card held at
    // an angle, tight enough to reject arbitrary quadrilaterals.
    request.quadratureTolerance = 28
    return request
  }

  private static func corners(_ o: VNRectangleObservation) -> [String: Any] {
    func pair(_ p: CGPoint) -> [String: Double] {
      ["x": Double(p.x), "y": Double(p.y)]
    }
    return [
      "topLeft": pair(o.topLeft),
      "topRight": pair(o.topRight),
      "bottomRight": pair(o.bottomRight),
      "bottomLeft": pair(o.bottomLeft),
      "confidence": Double(o.confidence),
    ]
  }

  // ---------------------------------------------------------------- plumbing

  /// Runs requests off the main thread.
  ///
  /// Accurate recognition on a full-resolution photo takes long enough to drop
  /// frames if it runs on the platform thread.
  private static func perform(
    _ requests: [VNRequest],
    on cgImage: CGImage,
    orientation: CGImagePropertyOrientation,
    onFailure: @escaping (FlutterError) -> Void
  ) {
    DispatchQueue.global(qos: .userInitiated).async {
      let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
      do {
        try handler.perform(requests)
      } catch {
        DispatchQueue.main.async {
          onFailure(FlutterError(code: "vision_failed", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  private static func cgOrientation(from o: UIImage.Orientation) -> CGImagePropertyOrientation {
    switch o {
    case .up: return .up
    case .down: return .down
    case .left: return .left
    case .right: return .right
    case .upMirrored: return .upMirrored
    case .downMirrored: return .downMirrored
    case .leftMirrored: return .leftMirrored
    case .rightMirrored: return .rightMirrored
    @unknown default: return .up
    }
  }
}
