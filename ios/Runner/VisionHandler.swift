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

  /// Whether to log what the detector is doing, frame by frame.
  #if DEBUG
  private static let kDebug = true
  #else
  private static let kDebug = false
  #endif

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
          variant: args["variant"] as? Int ?? 0,
          languages: args["languages"] as? [String] ?? [],
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
          byHand: args["byHand"] as? Bool ?? false,
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
  private static func recognize(
    path: String,
    boost: Bool,
    variant: Int,
    languages: [String],
    result: @escaping FlutterResult
  ) {
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
    let cgImage = boost ? boosted(full, variant: variant) ?? full : full

    // Decided before the request that reports it is built, because the
    // completion handler names it.
    let probe = VNRecognizeTextRequest()
    probe.recognitionLevel = .accurate
    let chosen = supportedLanguages(for: probe, preferring: languages)
    NSLog("Elapsa: reading in %@", chosen.joined(separator: ", "))

    let request = VNRecognizeTextRequest { request, error in
      if let error = error {
        result(FlutterError(code: "recognition_failed", message: error.localizedDescription, details: nil))
        return
      }
      let observations = request.results as? [VNRecognizedTextObservation] ?? []
      let elapsed = (CFAbsoluteTimeGetCurrent() - started) * 1000
      NSLog("Elapsa: recognised %d lines in %.0fms (%dx%d)%@",
            observations.count, elapsed, cgImage.width, cgImage.height,
            boost ? " boost#\(variant)" : "")

      // Where the writing is, as well as what it says.
      //
      // Not every document is a rectangle the detector can find. An open
      // passport is a curved spread with no closed outline — the data page
      // runs into the facing page across the fold — so nothing squares up, and
      // the only reliable statement about where the document *is* comes from
      // where its text is.
      let text = observations.compactMap { $0.topCandidates(1).first?.string }
        .joined(separator: "\n")
      // Reported back so the diagnostics screen can say which scripts were
      // actually enabled. Had this been visible, "Chinese is not recognised"
      // would have been one screenshot rather than several days.
      var payload: [String: Any] = ["text": text, "languages": chosen]

      // Every line with the box it was found in.
      //
      // So the caller can keep only what lies inside the document. A card
      // photographed on a desk is a photograph of the desk as well, and one
      // real scan came back with "return", "shift", "command" and "option" in
      // it — the card was lying on a laptop keyboard. Handing back positions
      // costs nothing and lets that be thrown away without a second pass over
      // the image, and without losing the view of the whole picture that says
      // whether the crop kept everything.
      payload["lines"] = observations.compactMap {
        (observation: VNRecognizedTextObservation) -> [String: Any]? in
        guard let line = observation.topCandidates(1).first?.string else {
          return nil
        }
        let box = observation.boundingBox

        // The best all-digit reading of this line, if it has one.
        //
        // A group of embossed figures often comes back as letters — one real
        // scan turned 6176 into Cyrillic — while the correct digits sit a
        // little further down the same list of candidates. Vision is asked for
        // several and the first that is nothing but digits is kept alongside
        // the winner, for the one job where a run of digits is exactly what is
        // being looked for. The winning candidate is untouched: this is extra
        // material for finding a card number, not a correction to the text.
        let digits = observation.topCandidates(6)
          .map { $0.string.replacingOccurrences(of: " ", with: "") }
          .first { candidate in
            candidate.count >= 3 && candidate.count <= 6
              && candidate.allSatisfy(\.isNumber)
          }

        var entry: [String: Any] = [
          "text": line,
          "x": box.minX,
          "y": 1.0 - box.maxY,
          "width": box.width,
          "height": box.height,
        ]
        if let digits = digits { entry["digits"] = digits }
        return entry
      }

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
    request.recognitionLanguages = chosen

    // And where the system can decide for itself, let it. The ordered list
    // above is a good guess about a document nobody has looked at yet; Vision
    // looking at the actual pixels is better than any guess.
    if #available(iOS 16.0, *) {
      request.automaticallyDetectsLanguage = true
    }

    // How small a line may be, as a fraction of the image height. Vision
    // discards anything shorter, and the default of 1/32 is too coarse here: a
    // machine-readable zone photographed from arm's length is a few
    // hundredths of the frame, so the one part of a passport that can be read
    // with certainty was being thrown away before parsing saw it.
    //
    // A fiftieth rather than an eightieth. The lower figure asked the
    // recogniser to consider a vast number of tiny candidate regions on a
    // twelve-megapixel photograph, and what it gave back was worse, not
    // better — a Chinese character carries far more detail than a Latin one
    // and suffers first when the budget is spread that thin.
    request.minimumTextHeight = 0.02

    // If Vision refuses a language this OS turns out not to have, the answer
    // is to read in English, not to give up on the picture.
    perform(
      [request],
      on: cgImage,
      orientation: cgOrientation(from: image.imageOrientation)
    ) { error in
      guard chosen != ["en-US"] else { result(error); return }
      NSLog("Elapsa: retrying in English after %@", error.message ?? "a failure")
      request.recognitionLanguages = ["en-US"]
      perform(
        [request],
        on: cgImage,
        orientation: cgOrientation(from: image.imageOrientation),
        onFailure: result
      )
    }
  }

  /// The image rebuilt to make raised figures legible.
  ///
  /// A card number is *embossed*, not printed: the digits are the same colour
  /// as the card and exist only as a shadow along one side of each stroke and
  /// a highlight along the other. There is almost no tone for a recogniser to
  /// find, which is why the flat-printed name and dates on the same card come
  /// back perfectly and the number comes back as nothing at all.
  ///
  /// Two treatments, because they fail in opposite conditions and one of them
  /// was making things worse:
  ///
  /// - `flatten` divides the image by a heavily blurred copy of itself. That
  ///   removes the *illumination* — whatever is smooth and large-scale — and
  ///   leaves only what varies within a few pixels, which is exactly what an
  ///   embossed stroke is. It works on a pale digit on a pale card, where a
  ///   plain contrast stretch cannot: stretching contrast on something already
  ///   near white simply clips it to white, taking the digits with it, which
  ///   is the likeliest reason the first attempt at this never helped.
  ///
  /// - `harden` is that first attempt, kept because it is the better tool on a
  ///   dark card, where the digits are lighter than their background and there
  ///   is real tone to pull apart.
  private static func boosted(_ cgImage: CGImage, variant: Int) -> CGImage? {
    let source = CIImage(cgImage: cgImage)

    guard let mono = CIFilter(name: "CIColorControls") else { return nil }
    mono.setValue(source, forKey: kCIInputImageKey)
    mono.setValue(0.0, forKey: kCIInputSaturationKey)
    guard let grey = mono.outputImage else { return nil }

    let treated: CIImage?
    switch variant {
    case 0: treated = relief(grey)
    case 1: treated = flatten(grey)
    case 2: treated = harden(grey)
    case 3: treated = enhance(source)
    default: treated = flatten(grey).flatMap(invert)
    }

    guard var output = treated else { return nil }

    // Enlarged before it is read.
    //
    // A recogniser has a size below which it will not look, and an embossed
    // number that survives this treatment as a faint relief is exactly the
    // kind of mark it gives up on. Scaling costs nothing but time and this
    // only runs when a number is already missing.
    let longest = max(output.extent.width, output.extent.height)
    if longest > 0, longest < 2400 {
      let factor = min(2400 / longest, 3)
      output = output.transformed(
        by: CGAffineTransform(scaleX: factor, y: factor)
      )
    }

    return ciContext.createCGImage(output, from: output.extent)
  }

  /// Apple's own document treatment, which is built for exactly this and
  /// costs one filter to try.
  private static func enhance(_ image: CIImage) -> CIImage? {
    guard let filter = CIFilter(name: "CIDocumentEnhancer") else { return nil }
    filter.setValue(image, forKey: kCIInputImageKey)
    filter.setValue(10.0, forKey: "inputAmount")
    return filter.outputImage?.cropped(to: image.extent)
  }

  /// The same relief, the other way up.
  ///
  /// Which way an embossed stroke reads depends on where the light was: from
  /// one side the digit is a shadow on a pale card, from the other it is a
  /// highlight. A recogniser trained on ink expects the former, so the frames
  /// lit from the wrong side are worth turning over rather than discarding.
  private static func invert(_ image: CIImage) -> CIImage? {
    guard let filter = CIFilter(name: "CIColorInvert") else { return nil }
    filter.setValue(image, forKey: kCIInputImageKey)
    return filter.outputImage?.cropped(to: image.extent)
  }

  /// Every edge in the picture, and nothing else.
  ///
  /// A morphological gradient — the image dilated minus the image eroded — is
  /// bright wherever brightness changes sharply within a couple of pixels and
  /// black everywhere it does not. An embossed digit is nothing *but* such a
  /// change: a shadow one side of the stroke and a highlight the other. The
  /// artwork it is printed over, however loud, is broad smooth colour, and
  /// broad smooth colour has no edges to give.
  ///
  /// This is the treatment for the hard case — a number stamped across a
  /// painted card, where it is dark against the light parts and light against
  /// the dark ones, so no single threshold anywhere on the card can separate
  /// it. Edges do not care which way round the contrast runs.
  ///
  /// Inverted at the end because what comes out is white strokes on black, and
  /// a recogniser trained on print expects ink on paper.
  private static func relief(_ grey: CIImage) -> CIImage? {
    guard let edges = CIFilter(name: "CIMorphologyGradient") else { return nil }
    edges.setValue(grey, forKey: kCIInputImageKey)
    // About the width of an embossed stroke's shadow. Wider starts joining
    // neighbouring digits into a blob.
    edges.setValue(3.0, forKey: kCIInputRadiusKey)
    guard let outline = edges.outputImage?.cropped(to: grey.extent) else {
      return nil
    }

    guard let stretch = CIFilter(name: "CIColorControls") else { return nil }
    stretch.setValue(outline, forKey: kCIInputImageKey)
    stretch.setValue(2.4, forKey: kCIInputContrastKey)
    stretch.setValue(0.15, forKey: kCIInputBrightnessKey)

    return stretch.outputImage
      .flatMap(invert)?
      .cropped(to: grey.extent)
  }

  /// Local contrast: the image divided by a blur of itself.
  private static func flatten(_ grey: CIImage) -> CIImage? {
    guard let blur = CIFilter(name: "CIGaussianBlur") else { return nil }
    blur.setValue(grey, forKey: kCIInputImageKey)
    // Wide enough to smooth away the digits themselves, so what remains after
    // the division is the digits and nothing else.
    blur.setValue(18.0, forKey: kCIInputRadiusKey)
    guard let background = blur.outputImage?.cropped(to: grey.extent) else {
      return nil
    }

    guard let divide = CIFilter(name: "CIDivideBlendMode") else { return nil }
    divide.setValue(grey, forKey: kCIInputImageKey)
    divide.setValue(background, forKey: kCIInputBackgroundImageKey)
    guard let flat = divide.outputImage else { return nil }

    // The division lands everything near white; this pulls the strokes back
    // down into something with ink in it.
    guard let stretch = CIFilter(name: "CIColorControls") else { return nil }
    stretch.setValue(flat, forKey: kCIInputImageKey)
    stretch.setValue(3.2, forKey: kCIInputContrastKey)
    stretch.setValue(-0.12, forKey: kCIInputBrightnessKey)
    return stretch.outputImage?.cropped(to: grey.extent)
  }

  /// Sharpen, then stretch. The right tool on a dark card.
  private static func harden(_ grey: CIImage) -> CIImage? {
    guard let sharpen = CIFilter(name: "CIUnsharpMask") else { return nil }
    sharpen.setValue(grey, forKey: kCIInputImageKey)
    sharpen.setValue(2.5, forKey: kCIInputRadiusKey)
    sharpen.setValue(2.2, forKey: kCIInputIntensityKey)
    guard let sharp = sharpen.outputImage else { return nil }

    guard let stretch = CIFilter(name: "CIColorControls") else { return nil }
    stretch.setValue(sharp, forKey: kCIInputImageKey)
    stretch.setValue(1.9, forKey: kCIInputContrastKey)
    stretch.setValue(-0.05, forKey: kCIInputBrightnessKey)
    return stretch.outputImage?.cropped(to: grey.extent)
  }

  /// Narrows the languages we want to the ones this OS actually ships, in the
  /// order the caller asked for.
  ///
  /// Order matters: Vision reads this list as priority, not as a set, and the
  /// language it tries first is the one it resolves an ambiguous glyph
  /// towards. The app decides that order from its own language setting, which
  /// is a statement by the user about what their documents are printed in.
  ///
  /// The filtering is the dangerous part, and it was doing real damage. The
  /// instance method that lists installed languages is deprecated and can
  /// throw, and the answer to a throw here was to fall back to English alone —
  /// silently, on every pass. A Chinese bank card then came back as
  /// "Il thi là H", which is Vision doing exactly as it was told: reading
  /// Chinese glyphs as Latin letters, because Chinese was never turned on.
  ///
  /// So the query is tried properly first, and a failure to answer is no
  /// longer taken as an answer. If nothing can say what is installed, the list
  /// is used as asked for — and if Vision then objects to a language it does
  /// not have, the request is run again in English, which is where that
  /// fallback belonged all along.
  private static func supportedLanguages(
    for request: VNRecognizeTextRequest,
    preferring wanted: [String] = []
  ) -> [String] {
    let order: [String]
    if !wanted.isEmpty {
      order = wanted
    } else if Locale.preferredLanguages.first?.hasPrefix("zh-Hant") ?? false {
      order = ["zh-Hant", "zh-Hans", "en-US"]
    } else {
      // Chinese leads even here. A Latin model transliterates Chinese rather
      // than admitting it cannot read it; a Chinese model reads Latin fine.
      order = ["zh-Hans", "zh-Hant", "en-US"]
    }

    var available: [String]?
    if #available(iOS 15.0, *) {
      available = try? VNRecognizeTextRequest.supportedRecognitionLanguages(
        for: request.recognitionLevel,
        revision: request.revision
      )
    }
    if available == nil {
      available = try? request.supportedRecognitionLanguages()
    }

    guard let installed = available, !installed.isEmpty else {
      // Nothing could tell us. Ask for what we want rather than for less.
      return order
    }

    let usable = order.filter { installed.contains($0) }
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

      let text = VNRecognizeTextRequest()
      text.recognitionLevel = .accurate
      text.usesLanguageCorrection = false
      text.recognitionLanguages = supportedLanguages(for: text)

      // The segmentation model too, and this one matters more: it is asked
      // for on the very first preview frame, so paying to load it there means
      // the brackets take a second to appear the first time the scanner is
      // opened — which reads as detection not working.
      let document = VNDetectDocumentSegmentationRequest()

      let handler = VNImageRequestHandler(cgImage: blank, options: [:])
      try? handler.perform([text, document])
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

    // Segmentation first, geometry second.
    //
    // VNDetectRectanglesRequest looks for four straight edges meeting at
    // roughly square corners. That is a description of a *shape*, not of a
    // document, so it finds table edges, laptop lids and window frames, and
    // misses the things that actually matter here: a passport whose pages
    // curve away from the fold, a white card on a white desk, a laminated
    // licence with the ceiling light across it. Loosening its thresholds only
    // trades one failure for the other — it starts finding the table.
    //
    // VNDetectDocumentSegmentation asks a trained model where the document is.
    // Apple ships it, it is what their own scanner uses, and it needs no data
    // of ours. Rectangles stay as the fallback for the frames it declines.
    let geometry = makeRectangleRequest { observation in
      result(observation.map(corners))
    }

    let started = CFAbsoluteTimeGetCurrent()
    let segmentation = VNDetectDocumentSegmentationRequest { request, _ in
      let found = (request.results as? [VNRectangleObservation])?
        .first { $0.confidence >= 0.5 }

      if kDebug {
        NSLog("Elapsa: segmentation %@ in %.0fms",
              found == nil ? "found nothing" : "found a document",
              (CFAbsoluteTimeGetCurrent() - started) * 1000)
      }

      if let found = found {
        result(corners(found))
      } else {
        perform([geometry], on: cgImage, orientation: .up) { _ in result(nil) }
      }
    }

    perform([segmentation], on: cgImage, orientation: .up) { _ in
      perform([geometry], on: cgImage, orientation: .up) { _ in result(nil) }
    }
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
    byHand: Bool,
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
      let spread: CGFloat = byHand ? 1.0 : 1.02
      func out(_ p: CGPoint) -> CIVector {
        CIVector(x: centre.x + (p.x - centre.x) * spread,
                 y: centre.y + (p.y - centre.y) * spread)
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

      // A hair of margin, but only around corners the *detector* found:
      // Vision puts them on the card's edge, and a crop exactly on that line
      // shaves the border off every card.
      //
      // None at all around corners a person placed. They put them where they
      // wanted the picture to end, and quietly widening that meant a crop
      // drawn tight against a card still came back with a rim of desk around
      // it — so the only way to get rid of the margin was to crop inside the
      // card and lose part of it.
      let margin = byHand ? 0 : min(box.rect.width, box.rect.height) * 0.02
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
         let br = supplied("bottomRight"), let bl = supplied("bottomLeft") {
        if let jpeg = cut((tl: tl, tr: tr, br: br, bl: bl)) {
          answer(jpeg, (tl: tl, tr: tr, br: br, bl: bl))
        } else {
          // Nothing else. Looking for a rectangle of our own here is how a
          // crop somebody drew by hand came back as a different rectangle
          // altogether — one found by the detector, and widened by the margin
          // the detector's corners need. The caller asked for *these* corners;
          // if they cannot be used, that is an answer, not an invitation to
          // substitute a guess.
          reply(nil)
        }
        return
      }
    }

    // Otherwise find the document again in the still itself, asking the
    // trained model before falling back to looking for a shape.
    func segment(then next: @escaping () -> Void) {
      let request = VNDetectDocumentSegmentationRequest { request, _ in
        guard
          let observation = (request.results as? [VNRectangleObservation])?
            .first(where: { $0.confidence >= 0.5 })
        else {
          next(); return
        }
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
    segment {
      find(relaxed: false) {
        find(relaxed: true) { reply(nil) }
      }
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
