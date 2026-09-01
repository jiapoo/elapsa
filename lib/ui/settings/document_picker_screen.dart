import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elapsa/core/theme.dart';
import 'package:elapsa/data/settings_repository.dart';
import 'package:elapsa/domain/document.dart';
import 'package:elapsa/l10n/app_localizations.dart';
import 'package:elapsa/ui/widgets/wallet_entry.dart';

/// What the user picked to send, and whether to seal it.
class ExportChoice {
  final Set<String> ids;
  final bool protect;

  const ExportChoice(this.ids, this.protect);
}

/// Choosing what to send, from the wallet as the user already knows it.
///
/// A list of names in a sheet was a second, worse way of looking at the same
/// documents — sorted differently, drawn differently, and giving no clue which
/// card was which for anyone who recognises their documents by sight. This is
/// the home screen with a tick on it: the same order, the same density, the
/// same pictures.
class DocumentPickerScreen extends ConsumerStatefulWidget {
  const DocumentPickerScreen({
    super.key,
    required this.documents,
    this.offerPassphrase = true,
  });

  final List<TrackedDocument> documents;

  /// A nearby handover leaves nothing behind for a passphrase to protect, so
  /// that path does not ask.
  final bool offerPassphrase;

  @override
  ConsumerState<DocumentPickerScreen> createState() =>
      _DocumentPickerScreenState();
}

class _DocumentPickerScreenState extends ConsumerState<DocumentPickerScreen> {
  late Set<String> _chosen = {for (final d in widget.documents) d.id};
  late bool _protect = widget.offerPassphrase;

  bool get _allChosen => _chosen.length == widget.documents.length;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final display = ref.watch(displayProvider);
    final ordered = orderedWallet(widget.documents, ref.watch(sortProvider), l);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.transferChoose),
        actions: [
          // One button, not two. "All" and "None" were never both useful at
          // once: whichever state you are in, only the other one does
          // anything, and the dead one is just something to misread.
          TextButton(
            onPressed: () => setState(() {
              _chosen = _allChosen
                  ? <String>{}
                  : {for (final d in widget.documents) d.id};
            }),
            child: Text(_allChosen ? l.transferNone : l.transferAll),
          ),
        ],
      ),
      body: display == WalletDisplay.imageOnly
          ? GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              childAspectRatio: kCardAspectRatio,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                for (final document in ordered)
                  _Selectable(
                    chosen: _chosen.contains(document.id),
                    onTap: () => _toggle(document.id),
                    child: IgnorePointer(
                      child: WalletEntry(document: document, display: display),
                    ),
                  ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                for (final document in ordered)
                  _Selectable(
                    chosen: _chosen.contains(document.id),
                    onTap: () => _toggle(document.id),
                    child: IgnorePointer(
                      child: WalletEntry(document: document, display: display),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.offerPassphrase)
                SwitchListTile(
                  value: _protect,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.transferProtect),
                  subtitle: Text(
                    l.transferProtectBody,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  onChanged: (on) => setState(() => _protect = on),
                ),
              FilledButton(
                onPressed: _chosen.isEmpty
                    ? null
                    : () =>
                          Navigator.of(context)
                              .pop(ExportChoice(_chosen, _protect)),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(l.transferSelected(_chosen.length)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggle(String id) => setState(() {
    if (!_chosen.remove(id)) _chosen.add(id);
  });
}

/// A wallet entry with a tick on it.
///
/// The unchosen are dimmed rather than hidden or outlined, so the ones going
/// are the ones that look normal — which is the right way round when the
/// question is what leaves this phone.
class _Selectable extends StatelessWidget {
  const _Selectable({
    required this.chosen,
    required this.onTap,
    required this.child,
  });

  final bool chosen;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: chosen ? 1 : 0.42,
            child: child,
          ),
          Positioned(
            right: 6,
            top: 6,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: chosen
                    ? scheme.primary
                    : Colors.black.withValues(alpha: 0.35),
                border: Border.all(color: Colors.white, width: 1.6),
              ),
              child: chosen
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
