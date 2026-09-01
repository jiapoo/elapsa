import Flutter
import Foundation
import Network
import UIKit

/// Handing a library to another phone with no file in between.
///
/// Bonjour over Network.framework, with peer-to-peer enabled — so two phones
/// find each other on a shared Wi-Fi network, and also over AWDL when there is
/// no network at all, which is the case that matters in an airport.
///
/// The protocol is deliberately small, because the payload is one archive and
/// there is nothing to negotiate:
///
///   1. The sender connects and says who it is.
///   2. The receiver shows that name and waits for a person to accept.
///   3. On accept it answers `ok`, and the sender writes the archive.
///   4. The receiver imports and answers `done`.
///
/// There is no passphrase. The handover is guarded by a person on the other
/// phone having to agree to it, and nothing is left on disk at either end for
/// a passphrase to protect afterwards — which is the whole reason to prefer
/// this to sending a file.
@objc class NearbyTransfer: NSObject {

  private static let service = "_elapsa._tcp"

  private static var events: FlutterEventSink?
  private static var listener: NWListener?
  private static var browser: NWBrowser?

  /// Connections we have accepted but not yet been told what to do with.
  private static var pending: NWConnection?

  /// What the browser can currently see, by the name shown to the user.
  private static var found: [String: NWEndpoint] = [:]

  private static let queue = DispatchQueue(label: "cc.elapsa.nearby")

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "cc.elapsa/nearby",
      binaryMessenger: registrar.messenger()
    )
    let stream = FlutterEventChannel(
      name: "cc.elapsa/nearby/events",
      binaryMessenger: registrar.messenger()
    )
    stream.setStreamHandler(StreamHandler())

    channel.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any] ?? [:]

      switch call.method {
      case "start":
        start(as: args["name"] as? String ?? UIDevice.current.name)
        result(nil)

      case "stop":
        stop()
        result(nil)

      case "send":
        guard
          let peer = args["peer"] as? String,
          let data = args["bytes"] as? FlutterStandardTypedData
        else {
          result(FlutterError(code: "bad_args", message: "send needs a peer and bytes", details: nil))
          return
        }
        send(to: peer, name: args["name"] as? String ?? UIDevice.current.name, data: data.data)
        result(nil)

      case "respond":
        respond(accept: args["accept"] as? Bool ?? false)
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Events

  private class StreamHandler: NSObject, FlutterStreamHandler {
    func onListen(withArguments _: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
      NearbyTransfer.events = eventSink
      return nil
    }

    func onCancel(withArguments _: Any?) -> FlutterError? {
      NearbyTransfer.events = nil
      return nil
    }
  }

  private static func emit(_ event: [String: Any]) {
    DispatchQueue.main.async { events?(event) }
  }

  // MARK: - Being findable, and looking

  private static func start(as name: String) {
    stop()

    let parameters = NWParameters.tcp
    // Lets two phones talk with no router between them.
    parameters.includePeerToPeer = true

    do {
      let listener = try NWListener(using: parameters)
      listener.service = NWListener.Service(name: name, type: service)
      listener.newConnectionHandler = { connection in receive(connection) }
      listener.start(queue: queue)
      self.listener = listener
    } catch {
      emit(["event": "failed", "reason": error.localizedDescription])
      return
    }

    let browser = NWBrowser(
      for: .bonjour(type: service, domain: nil),
      using: parameters
    )
    browser.browseResultsChangedHandler = { results, _ in
      var seen: [String: NWEndpoint] = [:]
      for result in results {
        if case let .service(serviceName, _, _, _) = result.endpoint {
          // Ourselves, seen in the mirror.
          if serviceName == name { continue }
          seen[serviceName] = result.endpoint
        }
      }
      found = seen
      emit(["event": "peers", "peers": Array(seen.keys)])
    }
    browser.start(queue: queue)
    self.browser = browser
  }

  private static func stop() {
    listener?.cancel()
    listener = nil
    browser?.cancel()
    browser = nil
    pending?.cancel()
    pending = nil
    found = [:]
  }

  // MARK: - Receiving

  private static func receive(_ connection: NWConnection) {
    // One at a time. A second phone dialling in halfway through a transfer
    // would be answered by a person who has already agreed to a different one.
    if pending != nil {
      connection.cancel()
      return
    }
    pending = connection

    connection.stateUpdateHandler = { state in
      if case let .failed(error) = state {
        emit(["event": "failed", "reason": error.localizedDescription])
        pending = nil
      }
    }
    connection.start(queue: queue)

    readFrame(connection) { hello in
      guard let hello = hello, let name = String(data: hello, encoding: .utf8) else {
        connection.cancel()
        pending = nil
        return
      }
      emit(["event": "invite", "name": name])
    }
  }

  private static func respond(accept: Bool) {
    guard let connection = pending else { return }

    guard accept else {
      writeFrame(connection, Data("no".utf8)) { _ in
        connection.cancel()
        pending = nil
      }
      return
    }

    writeFrame(connection, Data("ok".utf8)) { ok in
      guard ok else {
        connection.cancel()
        pending = nil
        return
      }
      readFrame(connection) { archive in
        defer {
          connection.cancel()
          pending = nil
        }
        guard let archive = archive else {
          emit(["event": "failed", "reason": "The transfer ended early."])
          return
        }
        emit([
          "event": "received",
          "bytes": FlutterStandardTypedData(bytes: archive),
        ])
      }
    }
  }

  // MARK: - Sending

  private static func send(to peer: String, name: String, data: Data) {
    guard let endpoint = found[peer] else {
      emit(["event": "failed", "reason": "That device is no longer nearby."])
      return
    }

    let parameters = NWParameters.tcp
    parameters.includePeerToPeer = true
    let connection = NWConnection(to: endpoint, using: parameters)

    connection.stateUpdateHandler = { state in
      switch state {
      case .ready:
        writeFrame(connection, Data(name.utf8)) { ok in
          guard ok else { return }
          readFrame(connection) { answer in
            let reply = answer.flatMap { String(data: $0, encoding: .utf8) }
            guard reply == "ok" else {
              emit(["event": "declined"])
              connection.cancel()
              return
            }
            emit(["event": "sending"])
            writeFrame(connection, data) { sent in
              emit(sent
                ? ["event": "sent"]
                : ["event": "failed", "reason": "The transfer was interrupted."])
              connection.cancel()
            }
          }
        }

      case let .failed(error):
        emit(["event": "failed", "reason": error.localizedDescription])
        connection.cancel()

      default:
        break
      }
    }
    connection.start(queue: queue)
  }

  // MARK: - Frames

  /// Length first, then that many bytes.
  ///
  /// TCP is a stream and knows nothing about where a message ends, so an
  /// archive read without a declared length would arrive in pieces with no way
  /// to tell a pause from an ending.
  private static func writeFrame(
    _ connection: NWConnection,
    _ payload: Data,
    _ done: @escaping (Bool) -> Void
  ) {
    var header = UInt32(payload.count).bigEndian
    var frame = Data(bytes: &header, count: 4)
    frame.append(payload)

    connection.send(
      content: frame,
      completion: .contentProcessed { error in done(error == nil) }
    )
  }

  private static func readFrame(
    _ connection: NWConnection,
    _ done: @escaping (Data?) -> Void
  ) {
    connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { header, _, _, error in
      guard error == nil, let header = header, header.count == 4 else {
        done(nil); return
      }
      let length = Int(header.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian })
      // An archive of a whole library, generously; anything larger is a bug or
      // somebody else's protocol arriving on our port.
      guard length > 0, length <= 256 * 1024 * 1024 else { done(nil); return }

      var body = Data()
      body.reserveCapacity(length)

      func more() {
        connection.receive(
          minimumIncompleteLength: 1,
          maximumLength: length - body.count
        ) { chunk, _, complete, error in
          if let chunk = chunk { body.append(chunk) }
          if body.count >= length {
            done(body)
          } else if error != nil || complete {
            done(nil)
          } else {
            emit(["event": "progress", "done": body.count, "total": length])
            more()
          }
        }
      }
      more()
    }
  }
}
