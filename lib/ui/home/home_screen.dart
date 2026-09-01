import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elapsa/core/labels.dart';
import 'package:elapsa/core/theme.dart';
import 'package:elapsa/data/document_repository.dart';
import 'package:elapsa/data/settings_repository.dart';
import 'package:elapsa/domain/document.dart';
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
          PopupMenuButton<DocumentSort>(
            icon: const Icon(Icons.swap_vert),
            tooltip: l.sortTitle,
            initialValue: ref.watch(sortProvider),
            onSelected: (sort) => ref.read(sortProvider.notifier).select(sort),
            itemBuilder: (context) => [
              for (final sort in DocumentSort.values)
                PopupMenuItem(value: sort, child: Text(sort.label(l))),
            ],
          ),
          PopupMenuButton<WalletDisplay>(
            icon: const Icon(Icons.dashboard_customize_outlined),
            tooltip: l.settingsWalletDisplay,
            initialValue: ref.watch(displayProvider),
            onSelected: (d) => ref.read(displayProvider.notifier).select(d),
            itemBuilder: (context) => [
              for (final display in WalletDisplay.values)
                PopupMenuItem(value: display, child: Text(display.label(l))),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: l.remindersTitle(0),
            onPressed: () => _showPendingReminders(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l.settingsTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
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
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          // Scanning is the way in that the app is actually built around.
          FloatingActionButton(
            heroTag: 'scan',
            tooltip: l.actionScan,
            onPressed: () => _scan(context),
            child: const Icon(Icons.photo_camera_outlined),
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

  Future<void> _showPendingReminders(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final pending = await ref.read(notificationServiceProvider).pending();
    if (!context.mounted) return;
    final l = L.of(context);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.remindersTitle(pending.length),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                pending.isEmpty ? l.remindersEmptyBody : l.remindersBody,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ...pending
                  .take(8)
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.schedule, size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text(p.title ?? '—')),
                        ],
                      ),
                    ),
                  ),
            ],
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
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
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
            Icon(Icons.hourglass_empty, size: 56, color: muted),
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
