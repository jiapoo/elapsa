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

  /// The quarter turn that lays a standing card down the right way up.
  ///
  /// Core Image works in a y-up space, where a positive angle turns
  /// anticlockwise. The two directions give landscape boxes of identical size
  /// and differ by a half turn, so this single sign decides whether a card
  /// photographed with the phone sideways comes out upright or inverted.
  private static let quarterTurn: CGFloat = -.pi / 2

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "cc.elapsa/vision",
      binaryMessenger: registrar.messenger()
    )

    channel.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any] ?? [:]

      switch call.method {
      case "prewarm":
        prewarm(result: result)

      case "recognize":
        guard let path = args["path"] as? String else {
          result(badArguments("recognize needs a path")); return
        }
        recognize(
          path: path,
          boost: args["boost"] as? Bool ?? false,
          result: result
        )

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
  private static func recognize(path: String, boost: Bool, result: @escaping FlutterResult) {
    guard
      let image = UIImage(contentsOfFile: path),
      let full = image.cgImage
    else {
      result(FlutterError(code: "unreadable_image", message: "Could not open \(path)", details: nil))
      return
    }

    // Full resolution, deliberately. Scaling the capture down before reading
    // it did cut the wait after the shutter, but it also cost the card number
    // and the expiry date — the two fields the whole app exists to capture.
    // Small print on a card needs every pixel the sensor gave it.
    let started = CFAbsoluteTimeGetCurrent()
    let cgImage = boost ? embossed(full) ?? full : full

    let request = VNRecognizeTextRequest { request, error in
      if let error = error {
        result(FlutterError(code: "recognition_failed", message: error.localizedDescription, details: nil))
        return
      }
      let observations = request.results as? [VNRecognizedTextObservation] ?? []
      let elapsed = (CFAbsoluteTimeGetCurrent() - started) * 1000
      NSLog("Elapsa: recognised %d lines in %.0fms (%dx%d)%@",
            observations.count, elapsed, cgImage.width, cgImage.height,
            boost ? " boosted" : "")

      // Where the writing is, as well as what it says.
      //
      // Not every document is a rectangle the detector can find. An open
      // passport is a curved spread with no closed outline — the data page
      // runs into the facing page across the fold — so nothing squares up, and
      // the only reliable statement about where the document *is* comes from
      // where its text is.
      let text = observations.compactMap { $0.topCandidates(1).first?.string }
        .joined(separator: "\n")
      var payload: [String: Any] = ["text": text]

      let boxes = observations.map(\.boundingBox)
      if let first = boxes.first {
        let union = boxes.dropFirst().reduce(first) { $0.union($1) }
        // Vision measures from the bottom left; Dart works from the top left.
        payload["bounds"] = [
          "x": union.minX,
          "y": 1.0 - union.maxY,
          "width": union.width,
          "height": union.height,
        ]
      }

      result(payload)
    }

    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false
    request.recognitionLanguages = supportedLanguages(for: request)

    // How small a line may be, as a fraction of the image height. Vision
    // *discards* anything shorter, and the default of 1/32 is far too coarse
    // for this: a machine-readable zone photographed from arm's length is a
    // couple of hundredths of the frame, so the one part of a passport that
    // can be read with certainty was being thrown away before parsing ever
    // saw it. Lower costs time on a big photo and buys back every document
    // that was not held close enough to fill it.
    request.minimumTextHeight = 0.012

    perform([request], on: cgImage,
            orientation: cgOrientation(from: image.imageOrientation),
            onFailure: result)
  }

  /// The image rebuilt to make raised figures legible.
  ///
  /// A card number is *embossed*, not printed: the digits are the same colour
  /// as the card and exist only as a shadow along one side of each stroke and
  /// a highlight along the other. There is almost no tonal difference for a
  /// recogniser to work with, which is why the flat-printed name and dates on
  /// the same card come back perfectly while the number comes back as nothing
  /// at all.
  ///
  /// So the shadow is turned into contrast. Colour goes first — it carries no
  /// information here and only dilutes the edges. An unsharp mask then pulls
  /// each stroke away from the card around it, and a hard contrast stretch
  /// turns what is left into something with actual black in it.
  ///
  /// This is a second pass, run only when the first found no number, because
  /// the same treatment hurts flat print: it blooms fine text and would cost
  /// the very fields that already read correctly.
  private static func embossed(_ cgImage: CGImage) -> CGImage? {
    let source = CIImage(cgImage: cgImage)

    guard let mono = CIFilter(name: "CIColorControls") else { return nil }
    mono.setValue(source, forKey: kCIInputImageKey)
    mono.setValue(0.0, forKey: kCIInputSaturationKey)
    guard let grey = mono.outputImage else { return nil }

    guard let sharpen = CIFilter(name: "CIUnsharpMask") else { return nil }
    sharpen.setValue(grey, forKey: kCIInputImageKey)
    sharpen.setValue(2.5, forKey: kCIInputRadiusKey)
    sharpen.setValue(2.2, forKey: kCIInputIntensityKey)
    guard let sharp = sharpen.outputImage else { return nil }

    guard let stretch = CIFilter(name: "CIColorControls") else { return nil }
    stretch.setValue(sharp, forKey: kCIInputImageKey)
    stretch.setValue(1.9, forKey: kCIInputContrastKey)
    stretch.setValue(-0.05, forKey: kCIInputBrightnessKey)
    guard let output = stretch.outputImage else { return nil }

    return ciContext.createCGImage(output, from: source.extent)
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

  /// Loads the recognition models before the user needs them.
  ///
  /// Vision pays for loading its language models on the first request, which
  /// otherwise lands on the first photo someone takes and reads as the app
  /// being slow. Called when the scanner opens, while they are still lining
  /// the card up.
  private static func prewarm(result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .utility).async {
      defer { DispatchQueue.main.async { result(nil) } }

      guard let context = CGContext(
        data: nil, width: 64, height: 64,
        bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGImageAlphaInfo.none.rawValue
      ), let blank = context.makeImage() else { return }

      let request = VNRecognizeTextRequest()
      request.recognitionLevel = .accurate
      request.usesLanguageCorrection = false
      request.recognitionLanguages = supportedLanguages(for: request)
      try? VNImageRequestHandler(cgImage: blank, options: [:]).perform([request])
      NSLog("Elapsa: vision prewarmed")
    }
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

    // Strict first, then loose — the same cascade the still uses.
    //
    // The preview only ever ran the strict pass, so the brackets could not
    // lock on to anything the strict pass rejects: a passport, which is not
    // card-shaped, and a card held far enough back to fall under the size
    // floor. The document was findable at capture and unfindable on screen,
    // which is the wrong way round — the preview is where the user needs to be
    // told it has been seen.
    let relaxed = makeRectangleRequest(relaxed: true) { observation in
      result(observation.map(corners))
    }

    let strict = makeRectangleRequest { observation in
      if let observation = observation {
        result(corners(observation))
      } else {
        perform([relaxed], on: cgImage, orientation: .up) { _ in result(nil) }
      }
    }

    perform([strict], on: cgImage, orientation: .up) { _ in result(nil) }
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
    // Off the platform thread: choosing an orientation runs Vision
    // synchronously, and doing that here would stall the interface.
    let reply: (Any?) -> Void = { value in
      DispatchQueue.main.async { result(value) }
    }

    DispatchQueue.global(qos: .userInitiated).async {
    guard let image = UIImage(contentsOfFile: path), let cgImage = image.cgImage else {
      reply(nil); return
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

    /// The card cut out and turned upright, or nil when the result is not
    /// plausibly a whole document.
    /// The quad's axis-aligned box, normalised, with a top-left origin — the
    /// same frame of reference Dart uses for the text bounds, so the two can
    /// be compared there.
    func normalisedBox(
      _ quad: (tl: CGPoint, tr: CGPoint, br: CGPoint, bl: CGPoint)
    ) -> [String: Double] {
      let xs = [quad.tl.x, quad.tr.x, quad.br.x, quad.bl.x]
      let ys = [quad.tl.y, quad.tr.y, quad.br.y, quad.bl.y]
      let minX = (xs.min()! - extent.origin.x) / extent.width
      let maxX = (xs.max()! - extent.origin.x) / extent.width
      let minY = (ys.min()! - extent.origin.y) / extent.height
      let maxY = (ys.max()! - extent.origin.y) / extent.height
      return [
        "x": Double(minX),
        "y": Double(1.0 - maxY),
        "width": Double(maxX - minX),
        "height": Double(maxY - minY),
      ]
    }

    func answer(
      _ jpeg: Data,
      _ quad: (tl: CGPoint, tr: CGPoint, br: CGPoint, bl: CGPoint)
    ) {
      reply([
        "bytes": FlutterStandardTypedData(bytes: jpeg),
        "bounds": normalisedBox(quad),
      ])
    }

    func cut(_ quad: (tl: CGPoint, tr: CGPoint, br: CGPoint, bl: CGPoint)) -> Data? {
      // The card's angle in the frame, taken from the edge Vision calls the
      // top. Note *Vision's* top: the corners are labelled against the image,
      // not the card, so with the phone held sideways this edge is the card's
      // short one and the box below comes out standing up.
      let angle = atan2(quad.tr.y - quad.tl.y, quad.tr.x - quad.tl.x)

      // Every document tracked here is wider than it is tall, so a box that
      // comes out portrait needs a quarter turn to lay it down.
      //
      // Which way round that turn goes is the whole question. Both directions
      // produce a landscape box of identical size, and they differ by a half
      // turn — so getting it backwards does not look like a rotation error at
      // all, it looks like the card came out upside down.
      var chosen = angle
      var quarterTurned = false
      if let standing = boxed(quad, turnedBy: angle),
         standing.rect.height > standing.rect.width {
        chosen = angle + quarterTurn
        quarterTurned = true
      }

      // The rigid crop doubles as the validity check: it is what rejects the
      // sliver you get when corners measured on the preview do not transfer to
      // a still of a different shape. Nothing is saved unless it passes.
      guard let cropped = crop(quad, turnedBy: chosen) else { return nil }

      // Then the card is squared up properly. Rotating alone leaves the
      // keystone in — a card photographed from anywhere but straight above is
      // a trapezium, and cutting its bounding box keeps the taper and adds a
      // wedge of desk down each side. A perspective correction pulls the four
      // corners onto a rectangle, so the saved face looks like the card rather
      // than like a photograph of one.
      //
      // This is safe for recognition in a way it would not have been before:
      // text is read from the full-resolution original, never from this crop,
      // so warping the saved face cannot cost a single character.
      let face = rectified(quad, quarterTurned: quarterTurned) ?? cropped

      return ciContext.jpegRepresentation(
        of: face,
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.9]
      )
    }

    /// The card pulled flat onto a rectangle, or nil if the filter will not
    /// produce something plausible.
    func rectified(
      _ quad: (tl: CGPoint, tr: CGPoint, br: CGPoint, bl: CGPoint),
      quarterTurned: Bool
    ) -> CIImage? {
      // A hair of margin, taken outward from the centre, for the same reason
      // the rigid crop has one: Vision's corners sit *on* the card's edge, and
      // correcting exactly to that line shaves the border off every card.
      let centre = CGPoint(
        x: (quad.tl.x + quad.tr.x + quad.br.x + quad.bl.x) / 4,
        y: (quad.tl.y + quad.tr.y + quad.br.y + quad.bl.y) / 4
      )
      func out(_ p: CGPoint) -> CIVector {
        CIVector(x: centre.x + (p.x - centre.x) * 1.02,
                 y: centre.y + (p.y - centre.y) * 1.02)
      }

      // A quarter turn is a relabelling of which corner becomes the output's
      // top-left. Turning the content a further 90° counter-clockwise puts
      // what was the top-right corner into the top-left position, and the rest
      // follow round — the same turn, and the same direction, that the rigid
      // crop applies.
      let tl = quarterTurned ? quad.tr : quad.tl
      let tr = quarterTurned ? quad.br : quad.tr
      let br = quarterTurned ? quad.bl : quad.br
      let bl = quarterTurned ? quad.tl : quad.bl

      guard let filter = CIFilter(name: "CIPerspectiveCorrection") else { return nil }
      filter.setValue(ciImage, forKey: kCIInputImageKey)
      filter.setValue(out(tl), forKey: "inputTopLeft")
      filter.setValue(out(tr), forKey: "inputTopRight")
      filter.setValue(out(br), forKey: "inputBottomRight")
      filter.setValue(out(bl), forKey: "inputBottomLeft")

      guard let output = filter.outputImage else { return nil }
      let box = output.extent

      // A badly-formed quad — three corners nearly in a line — makes this
      // filter produce something enormous or infinite rather than failing.
      let longestSide = max(extent.width, extent.height)
      guard
        box.width.isFinite, box.height.isFinite,
        box.width > longestSide * 0.10,
        box.height > longestSide * 0.10,
        box.width < longestSide * 2, box.height < longestSide * 2
      else { return nil }

      return output
    }

    /// The cropped card at one candidate rotation, validated for size.
    func crop(_ quad: (tl: CGPoint, tr: CGPoint, br: CGPoint, bl: CGPoint),
              turnedBy angle: CGFloat) -> CIImage? {
      guard let box = boxed(quad, turnedBy: angle) else { return nil }

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
      return cropped.extent.isEmpty ? nil : cropped
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
        answer(jpeg, (tl: tl, tr: tr, br: br, bl: bl))
        return
      }
    }

    // Otherwise find the card again in the still itself.
    func find(relaxed: Bool, then next: @escaping () -> Void) {
      let request = makeRectangleRequest(relaxed: relaxed) { observation in
        guard let observation = observation else { next(); return }
        let quad = (
          tl: point(observation.topLeft),
          tr: point(observation.topRight),
          br: point(observation.bottomRight),
          bl: point(observation.bottomLeft)
        )
        guard let jpeg = cut(quad) else { next(); return }
        answer(jpeg, quad)
      }
      perform([request], on: cgImage, orientation: orientation) { _ in next() }
    }

    // Strict first, then loose. The tight thresholds are what keep a table
    // edge or a windowsill from being mistaken for a card, so they stay in
    // charge of the first look. But a document that is not flat — an open
    // passport, whose pages curve away towards the fold — has no square
    // corners to offer, and failing it outright is worse than accepting a
    // rougher quadrilateral.
    find(relaxed: false) {
      find(relaxed: true) { reply(nil) }
    }
    }
  }

  private static func makeRectangleRequest(
    relaxed: Bool = false,
    _ completion: @escaping (VNRectangleObservation?) -> Void
  ) -> VNDetectRectanglesRequest {
    let request = VNDetectRectanglesRequest { request, _ in
      // The largest, not the most confident. Vision ranks by confidence, and
      // on a document the most confident rectangle is often a panel *inside*
      // it — the tinted field behind a passport's data, whose edges are
      // cleaner than the page's own. Picking that one framed the data page
      // and left the machine-readable zone outside the crop. The document is
      // the biggest thing the user was pointing at.
      let found = (request.results as? [VNRectangleObservation])?
        .max { a, b in
          a.boundingBox.width * a.boundingBox.height
            < b.boundingBox.width * b.boundingBox.height
        }
      completion(found)
    }

    // Vision expresses aspect ratio as short side over long side. An ID-1 card
    // is 0.63 and a passport data page about 0.70, so this window covers the
    // documents we track while rejecting the long thin shapes that windowsills
    // and table edges produce.
    // Vision expresses aspect ratio as short side over long side. An ID-1
    // card is 0.63 and a passport data page about 0.70; an open passport is
    // squarer still, which is what the relaxed ceiling is for.
    request.minimumAspectRatio = relaxed ? 0.30 : 0.45
    request.maximumAspectRatio = relaxed ? 1.00 : 0.95

    // Size is a fraction of the frame. A quarter of it demanded the card be
    // held closer than people naturally hold one, and a document that fills a
    // fifth of the picture is still unmistakably the subject of it.
    request.minimumSize = relaxed ? 0.12 : 0.18
    request.minimumConfidence = relaxed ? 0.4 : 0.62
    request.maximumObservations = relaxed ? 6 : 3
    // How far from square the corners may be. Loose enough for a card held at
    // an angle, tight enough to reject arbitrary quadrilaterals — and looser
    // still on the second look, for a page that is curved rather than flat.
    request.quadratureTolerance = relaxed ? 45 : 28
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
