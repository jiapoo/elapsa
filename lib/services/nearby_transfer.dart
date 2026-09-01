import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Something that happened on the wire.
sealed class NearbyEvent {
  const NearbyEvent();
}

/// One device on the network.
///
/// The identity and the name are separate because the name is not unique and
/// not even stable — two phones both called "iPhone" are an ordinary thing to
/// find in a room, and Bonjour renames one of them behind your back.
class NearbyPeer {
  final String id;
  final String name;

  const NearbyPeer(this.id, this.name);
}

/// The devices currently visible.
class NearbyPeers extends NearbyEvent {
  final List<NearbyPeer> peers;
  const NearbyPeers(this.peers);
}

/// Somebody is offering to send, and is waiting to be let in.
class NearbyInvite extends NearbyEvent {
  final String from;
  const NearbyInvite(this.from);
}

/// The other side said no.
class NearbyDeclined extends NearbyEvent {
  const NearbyDeclined();
}

/// The archive is on its way out.
class NearbySending extends NearbyEvent {
  const NearbySending();
}

/// It arrived at the other end.
class NearbySent extends NearbyEvent {
  const NearbySent();
}

/// An archive arrived here.
class NearbyReceived extends NearbyEvent {
  final Uint8List bytes;
  const NearbyReceived(this.bytes);
}

class NearbyProgress extends NearbyEvent {
  final int done;
  final int total;
  const NearbyProgress(this.done, this.total);

  double get fraction => total <= 0 ? 0 : done / total;
}

class NearbyFailed extends NearbyEvent {
  final String reason;
  const NearbyFailed(this.reason);
}

/// Handing a library to another phone with no file in between.
///
/// The archive is the same one the export writes; only the transport differs.
/// There is no passphrase here, and that is not a shortcut: the handover is
/// guarded by a person on the other phone agreeing to it, and nothing is left
/// on disk at either end for a passphrase to protect afterwards. A file has
/// the opposite problem, which is why a file still asks for one.
class NearbyTransfer {
  const NearbyTransfer();

  static const _channel = MethodChannel('cc.elapsa/nearby');
  static const _events = EventChannel('cc.elapsa/nearby/events');

  /// Whether this platform has the transport at all.
  ///
  /// Android has no implementation yet — the app has never been built for it —
  /// so the file archive remains the way across for anyone on one.
  static bool get isAvailable => defaultTargetPlatform == TargetPlatform.iOS;

  Stream<NearbyEvent> get events => _events
      .receiveBroadcastStream()
      .map(_decode)
      .where((e) => e != null)
      .cast();

  /// Becomes findable, and starts looking. Both at once, because either phone
  /// may turn out to be the one sending.
  Future<void> start({required String name}) =>
      _channel.invokeMethod<void>('start', {'name': name});

  Future<void> stop() => _channel.invokeMethod<void>('stop');

  Future<void> send({
    required String peer,
    required String name,
    required Uint8List bytes,
  }) => _channel.invokeMethod<void>('send', {
    'peer': peer,
    'name': name,
    'bytes': bytes,
  });

  /// Answers an invitation. Nothing crosses until this says so.
  Future<void> respond({required bool accept}) =>
      _channel.invokeMethod<void>('respond', {'accept': accept});

  static NearbyEvent? _decode(Object? raw) {
    if (raw is! Map) return null;
    final event = raw['event'];

    return switch (event) {
      'peers' => NearbyPeers([
        for (final peer in (raw['peers'] as List? ?? const []))
          if (peer is Map)
            NearbyPeer(
              peer['id'] as String? ?? '',
              (peer['name'] as String?)?.trim().isNotEmpty == true
                  ? peer['name'] as String
                  : (peer['id'] as String? ?? '?'),
            ),
      ]),
      'invite' => NearbyInvite(raw['name'] as String? ?? '?'),
      'declined' => const NearbyDeclined(),
      'sending' => const NearbySending(),
      'sent' => const NearbySent(),
      'received' => NearbyReceived(raw['bytes'] as Uint8List),
      'progress' => NearbyProgress(
        (raw['done'] as num?)?.toInt() ?? 0,
        (raw['total'] as num?)?.toInt() ?? 0,
      ),
      'failed' => NearbyFailed(raw['reason'] as String? ?? ''),
      _ => null,
    };
  }
}
