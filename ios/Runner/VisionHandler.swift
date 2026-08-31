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
        extractCard(
          path: path,
          corners: args["corners"] as? [String: [String: NSNumber]],
          result: result
        )

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

  /// Detects the card in a full-resolution capture and cuts it out.
  ///
  /// Deliberately a **rigid** transform — rotate and crop, nothing more.
  ///
  /// A perspective warp can straighten a card photographed at an angle, but it
  /// does so by stretching the far edge to match the near one, which smears
  /// exactly the small print an expiry date is written in. The app avoids that
  /// by refusing the shot until the card is square to the camera, so by the
  /// time this runs there is no perspective left to correct. Rotating to the
  /// card's own angle and cropping to its corners keeps every pixel where the
  /// lens put it.
  ///
  /// When [corners] is supplied — the quad the scanner had locked on as the
  /// shutter fired — those are used directly. Detecting afresh on the still
  /// can settle on a different rectangle, which is how a user ends up with
  /// brackets around their card and a photograph of the desk beside it.
  ///
  /// Returns nil when there is nothing to work with; the caller falls back to
  /// a plain centre crop.
  private static func extractCard(
    path: String,
    corners: [String: [String: NSNumber]]?,
    result: @escaping FlutterResult
  ) {
    guard let image = UIImage(contentsOfFile: path), let cgImage = image.cgImage else {
      result(nil); return
    }

    let orientation = cgOrientation(from: image.imageOrientation)
    let ciImage = CIImage(cgImage: cgImage).oriented(orientation)
    let extent = ciImage.extent

    /// Normalised Vision point to image space. Both use a bottom-left origin,
    /// so this is a plain scale.
    func point(_ p: CGPoint) -> CGPoint {
      CGPoint(x: extent.origin.x + p.x * extent.width,
              y: extent.origin.y + p.y * extent.height)
    }

    /// Rotates to the card's own angle and crops to its corners, or returns
    /// nil when the result is not plausibly a whole document.
    ///
    /// The check matters because the preview stream and the still can differ
    /// in aspect ratio — 16:9 against 4:3 — so corners measured on one do not
    /// always transfer to the other. When they do not, the crop comes out as a
    /// shifted sliver, and a sliver of someone's card is worse than falling
    /// back to a rougher cut of the whole thing.
    /// The bounding box of the quad once the image is turned by [angle].
    func boxed(_ quad: (tl: CGPoint, tr: CGPoint, br: CGPoint, bl: CGPoint),
               turnedBy angle: CGFloat) -> (rect: CGRect, transform: CGAffineTransform)? {
      let rotation = CGAffineTransform(rotationAngle: -angle)
      let rotated = [quad.tl, quad.tr, quad.br, quad.bl].map { $0.applying(rotation) }
      let xs = rotated.map(\.x)
      let ys = rotated.map(\.y)
      guard
        let minX = xs.min(), let maxX = xs.max(),
        let minY = ys.min(), let maxY = ys.max(),
        maxX > minX, maxY > minY
      else { return nil }
      return (CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY),
              rotation)
    }

    func cut(_ quad: (tl: CGPoint, tr: CGPoint, br: CGPoint, bl: CGPoint)) -> Data? {
      // The card's own angle in the frame, taken from its top edge. Undoing
      // just this leaves the document upright without touching its geometry.
      let angle = atan2(quad.tr.y - quad.tl.y, quad.tr.x - quad.tl.x)
      guard var box = boxed(quad, turnedBy: angle) else { return nil }

      // Every document Elapsa tracks is wider than it is tall. Coming out
      // portrait means the detector called the short side the top — which is
      // what happens when the phone is held sideways — so a further quarter
      // turn lays the card down. Which way to turn is decided here by the
      // shape that came out, not assumed from the device.
      if box.rect.height > box.rect.width {
        guard let turned = boxed(quad, turnedBy: angle + .pi / 2) else { return nil }
        box = turned
      }

      // A hair of margin. Vision's corners sit on the card's edge, and a crop
      // exactly on that line shaves the border off every card.
      let margin = min(box.rect.width, box.rect.height) * 0.02
      let generous = box.rect.insetBy(dx: -margin, dy: -margin)

      let turnedImage = ciImage.transformed(by: box.transform)
      let rect = generous.intersection(turnedImage.extent)
      guard !rect.isNull, !rect.isEmpty else { return nil }

      // A real document fills a meaningful share of a frame the user framed it
      // in. Loose enough for a card held well back, tight enough to reject the
      // sliver you get when corners measured on the preview do not transfer to
      // a still of a different shape.
      let longestSide = max(extent.width, extent.height)
      guard
        rect.width > longestSide * 0.10,
        rect.height > longestSide * 0.10,
        rect.width * rect.height > extent.width * extent.height * 0.04
      else { return nil }

      let cropped = turnedImage.cropped(to: rect)
      guard !cropped.extent.isEmpty else { return nil }

      return ciContext.jpegRepresentation(
        of: cropped,
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.9]
      )
    }

    // First choice: the corners the user actually saw.
    if let corners = corners {
      // Dart works in a top-left origin; flip back to Vision's bottom-left.
      func supplied(_ key: String) -> CGPoint? {
        guard
          let p = corners[key],
          let x = p["x"]?.doubleValue,
          let y = p["y"]?.doubleValue
        else { return nil }
        return point(CGPoint(x: x, y: 1.0 - y))
      }

      if let tl = supplied("topLeft"), let tr = supplied("topRight"),
         let br = supplied("bottomRight"), let bl = supplied("bottomLeft"),
         let jpeg = cut((tl: tl, tr: tr, br: br, bl: bl)) {
        result(FlutterStandardTypedData(bytes: jpeg))
        return
      }
    }

    // Otherwise find the card again in the still itself.
    let request = makeRectangleRequest { observation in
      guard
        let observation = observation,
        let jpeg = cut((
          tl: point(observation.topLeft),
          tr: point(observation.topRight),
          br: point(observation.bottomRight),
          bl: point(observation.bottomLeft)
        ))
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
