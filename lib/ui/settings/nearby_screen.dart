import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elapsa/data/document_repository.dart';
import 'package:elapsa/l10n/app_localizations.dart';
import 'package:elapsa/services/document_archive.dart';
import 'package:elapsa/services/nearby_transfer.dart';
import 'package:elapsa/ui/widgets/document_card_face.dart';

/// Two phones in the same room.
///
/// Both sides advertise and both sides look, because either may turn out to be
/// the one sending, and asking someone to pick a role before they have picked
/// a device is a question about the app rather than about what they want.
class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key, required this.selected});

  /// The documents this device would send, if it turns out to be the sender.
  final Set<String> selected;

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  static const _nearby = NearbyTransfer();

  StreamSubscription<NearbyEvent>? _subscription;
  List<String> _peers = const [];
  String? _status;
  double? _progress;
  bool _busy = false;
  String _name = '';

  @override
  void initState() {
    super.initState();
    _begin();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _nearby.stop();
    super.dispose();
  }

  Future<void> _begin() async {
    if (!NearbyTransfer.isAvailable) return;

    // The name the other phone will show. Its own device name, because that is
    // what the person holding it will recognise, and they are standing next to
    // whoever is looking at the list.
    _name = Platform.localHostname.replaceAll('.local', '');

    _subscription = _nearby.events.listen(_handle);
    await _nearby.start(name: _name);
    if (mounted) setState(() {});
  }

  Future<void> _handle(NearbyEvent event) async {
    if (!mounted) return;
    final l = L.of(context);

    switch (event) {
      case NearbyPeers(:final names):
        setState(() => _peers = names);

      case NearbyInvite(:final from):
        final accept = await _askToAccept(from);
        await _nearby.respond(accept: accept ?? false);
        if (mounted && (accept ?? false)) {
          setState(() {
            _busy = true;
            _status = l.nearbyReceiving;
          });
        }

      case NearbyProgress(:final fraction):
        setState(() => _progress = fraction);

      case NearbySending():
        setState(() => _busy = true);

      case NearbySent():
        setState(() {
          _busy = false;
          _progress = null;
          _status = l.nearbySentTo;
        });

      case NearbyDeclined():
        setState(() {
          _busy = false;
          _progress = null;
          _status = l.nearbyDeclined;
        });

      case NearbyReceived(:final bytes):
        await _import(bytes);

      case NearbyFailed(:final reason):
        setState(() {
          _busy = false;
          _progress = null;
          _status = reason;
        });
    }
  }

  Future<void> _import(Uint8List bytes) async {
    final l = L.of(context);
    try {
      final archived = await const DocumentArchive().unpack(bytes);
      final count = await ref
          .read(documentRepositoryProvider)
          .importAll(archived);

      // Pictures are cached by document and page, and an import replaces the
      // contents behind keys that have not changed.
      ref.invalidate(documentImageProvider);

      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
          _status = l.transferImported(count);
        });
      }
    } on ArchiveException {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
          _status = l.transferFailedFile;
        });
      }
    }
  }

  Future<bool?> _askToAccept(String from) {
    final l = L.of(context);

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l.nearbyInvite(from)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.nearbyDecline),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.nearbyAccept),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTo(String peer) async {
    final l = L.of(context);
    setState(() {
      _busy = true;
      _status = l.nearbyWaiting(peer);
    });

    final documents = await ref
        .read(documentRepositoryProvider)
        .exportDocuments(widget.selected);

    // No passphrase. The handover is guarded by a person on the other phone
    // agreeing to it, and nothing is left on disk at either end afterwards for
    // one to protect — which is the whole reason to prefer this to a file.
    final bytes = await const DocumentArchive().pack(documents);
    if (!mounted) return;

    await _nearby.send(peer: peer, name: _name, bytes: bytes);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.nearbyTitle)),
      body: !NearbyTransfer.isAvailable
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l.nearbyUnavailable,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(
                  l.nearbyBody,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
                ),
                const SizedBox(height: 20),

                if (_status != null) ...[
                  _Banner(text: _status!, progress: _progress),
                  const SizedBox(height: 20),
                ],

                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: _peers.isEmpty && !_busy
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : Icon(
                              Icons.wifi_tethering,
                              size: 16,
                              color: scheme.primary,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _peers.isEmpty ? l.nearbySearching : l.nearbyTitle,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_peers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      l.nearbyNone,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  )
                else
                  for (final peer in _peers)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.smartphone, color: scheme.primary),
                      title: Text(peer),
                      trailing: FilledButton(
                        onPressed: _busy ? null : () => _sendTo(peer),
                        child: Text(l.nearbySend),
                      ),
                    ),

                const SizedBox(height: 28),
                Text(
                  '${l.nearbyName}  $_name',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
    );
  }
}

/// What is happening right now, and how far along it is.
class _Banner extends StatelessWidget {
  const _Banner({required this.text, this.progress});

  final String text;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: progress, minHeight: 6),
            ),
          ],
        ],
      ),
    );
  }
}
