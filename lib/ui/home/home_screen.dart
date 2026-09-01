import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elapsa/core/labels.dart';
import 'package:elapsa/core/theme.dart';
import 'package:elapsa/data/document_repository.dart';
import 'package:elapsa/data/settings_repository.dart';
import 'package:elapsa/domain/document.dart';
import 'package:elapsa/domain/document_type.dart';
import 'package:elapsa/l10n/app_localizations.dart';
import 'package:elapsa/ui/edit/edit_document_screen.dart';
import 'package:elapsa/ui/scan/scan_screen.dart';
import 'package:elapsa/ui/settings/settings_screen.dart';
import 'package:elapsa/ui/widgets/wallet_entry.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final documents = ref.watch(documentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          // One control where there were two menus and a bell. Sorting and
          // density are the same question asked twice — how do I want to look
          // at this — so they are answered on one surface, where the options
          // can be read as words rather than guessed from an icon.
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: l.homeArrange,
            onPressed: () => _arrange(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: l.settingsTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: documents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (docs) => docs.isEmpty
            ? const _EmptyState()
            : _Wallet(
                documents: docs,
                sort: ref.watch(sortProvider),
                display: ref.watch(displayProvider),
              ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Manual entry is the fallback, so it gets the quieter of the two.
          FloatingActionButton(
            heroTag: 'add',
            tooltip: l.actionAdd,
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const EditDocumentScreen(),
              ),
            ),
            child: const Icon(Icons.add_rounded),
          ),
          const SizedBox(height: 12),
          // Scanning is the way in that the app is actually built around.
          FloatingActionButton(
            heroTag: 'scan',
            tooltip: l.actionScan,
            onPressed: () => _scan(context),
            child: const Icon(Icons.document_scanner_rounded),
          ),
        ],
      ),
    );
  }

  Future<void> _scan(BuildContext context) async {
    final session = await Navigator.of(
      context,
    ).push<ScanSession>(MaterialPageRoute(builder: (_) => const ScanScreen()));
    if (session == null || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditDocumentScreen(session: session),
      ),
    );
  }

  /// How the wallet is laid out, asked once.
  Future<void> _arrange(BuildContext context, WidgetRef ref) {
    final l = L.of(context);

    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.homeArrange,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),

                _ArrangeGroup(
                  title: l.homeSortBy,
                  children: [
                    for (final sort in DocumentSort.values)
                      _ArrangeOption(
                        label: sort.label(l),
                        chosen: ref.watch(sortProvider) == sort,
                        onTap: () =>
                            ref.read(sortProvider.notifier).select(sort),
                      ),
                  ],
                ),
                const SizedBox(height: 22),

                _ArrangeGroup(
                  title: l.homeShowAs,
                  children: [
                    for (final display in WalletDisplay.values)
                      _ArrangeOption(
                        label: display.label(l),
                        chosen: ref.watch(displayProvider) == display,
                        onTap: () =>
                            ref.read(displayProvider.notifier).select(display),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A heading and its choices.
class _ArrangeGroup extends StatelessWidget {
  const _ArrangeGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

/// One choice, shown as what it says rather than as a symbol to decode.
class _ArrangeOption extends StatelessWidget {
  const _ArrangeOption({
    required this.label,
    required this.chosen,
    required this.onTap,
  });

  final String label;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: chosen
          ? scheme.primary.withValues(alpha: 0.12)
          : scheme.surfaceContainerHigh.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(Radii.chip),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.chip),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.chip),
            border: Border.all(
              color: chosen ? scheme.primary : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: chosen ? scheme.primary : scheme.onSurface,
              fontWeight: chosen ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _Wallet extends StatelessWidget {
  const _Wallet({
    required this.documents,
    required this.sort,
    required this.display,
  });

  final List<TrackedDocument> documents;
  final DocumentSort sort;
  final WalletDisplay display;

  /// Orders one section.
  ///
  /// Expiry is the tie-breaker for every other choice, because two documents
  /// of the same type or the same age are still not equally urgent.
  List<TrackedDocument> _ordered(List<TrackedDocument> documents, L l) =>
      orderedWallet(documents, sort, l);

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final needsAttention = _ordered(
      documents.where((d) => d.status() != DocumentStatus.valid).toList(),
      l,
    );
    final rest = _ordered(
      documents.where((d) => d.status() == DocumentStatus.valid).toList(),
      l,
    );

    // Sorting by type means grouping by it. A list ordered by type without
    // saying where each type begins is a list you have to read to navigate,
    // which is the opposite of what sorting it was for.
    if (sort == DocumentSort.type) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
        children: [
          // The triage band survives, ungrouped and first. It is not a sort —
          // it is the answer to "is anything wrong", and breaking it up under
          // type headings buries that answer.
          //
          // And it is a lens, not a bucket: a passport that needs attention is
          // still a passport, so it appears here *and* under its type below.
          // Moving it out would leave a hole in the type it belongs to, which
          // reads as a document that has gone missing.
          if (needsAttention.isNotEmpty) ...[
            _SectionHeader(l.homeNeedsAttention),
            _section(needsAttention),
            const SizedBox(height: 24),
          ],
          // Tight. A heading with two cards under it does not need the gap
          // that separates the triage band from everything else; at that
          // spacing a wallet of eight documents reads as eight lists.
          for (final group in _byType(documents, l)) ...[
            _SectionHeader(group.key.label(l), tight: true),
            _section(group.value),
            const SizedBox(height: 6),
          ],
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
      children: [
        if (needsAttention.isNotEmpty) ...[
          _SectionHeader(l.homeNeedsAttention),
          _section(needsAttention),
          const SizedBox(height: 24),
        ],
        if (rest.isNotEmpty) ...[
          _SectionHeader(l.homeEverythingElse),
          _section(rest),
        ],
      ],
    );
  }

  /// The documents gathered under their type, the types in the order the
  /// user's own language puts them.
  List<MapEntry<DocumentType, List<TrackedDocument>>> _byType(
    List<TrackedDocument> documents,
    L l,
  ) {
    final groups = <DocumentType, List<TrackedDocument>>{};
    for (final document in documents) {
      groups.putIfAbsent(document.type, () => []).add(document);
    }

    final entries = groups.entries.toList()
      ..sort((a, b) => a.key.label(l).compareTo(b.key.label(l)));
    return entries;
  }

  /// One section, arranged to suit the size of what is in it.
  ///
  /// A small card leaves most of a phone's width unused, so the picture-only
  /// wallet pairs them up rather than running a narrow column down the middle
  /// of the screen.
  Widget _section(List<TrackedDocument> documents) {
    if (display == WalletDisplay.imageOnly) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        // Zero, explicitly. A grid nested in a scroll view still takes the
        // ambient inset for its own padding, and under a type heading that
        // arrived as a band of empty space nobody asked for.
        padding: EdgeInsets.zero,
        childAspectRatio: kCardAspectRatio,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          for (final document in documents)
            WalletEntry(document: document, display: display),
        ],
      );
    }

    return Column(
      children: [
        for (final document in documents)
          WalletEntry(document: document, display: display),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.tight = false});

  final String title;

  /// For a heading that follows another group rather than opening the page.
  final bool tight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: tight
          ? const EdgeInsets.fromLTRB(4, 10, 4, 8)
          : const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// One document, at whichever density the user asked for.
///
/// The status always survives. Whatever else is hidden, an app whose entire
/// purpose is telling you when to start renewing cannot show a list that does
/// not say.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style_rounded, size: 56, color: muted),
            const SizedBox(height: 20),
            Text(
              l.homeEmptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              l.homeEmptyBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: muted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
