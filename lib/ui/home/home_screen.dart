import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elapsa/core/labels.dart';
import 'package:elapsa/core/theme.dart';
import 'package:elapsa/data/document_repository.dart';
import 'package:elapsa/domain/document.dart';
import 'package:elapsa/l10n/app_localizations.dart';
import 'package:elapsa/ui/edit/edit_document_screen.dart';
import 'package:elapsa/ui/scan/scan_screen.dart';
import 'package:elapsa/ui/settings/settings_screen.dart';
import 'package:elapsa/ui/widgets/document_card_face.dart';

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
        data: (docs) =>
            docs.isEmpty ? const _EmptyState() : _Wallet(documents: docs),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Manual entry is the fallback, so it gets the quieter of the two.
          FloatingActionButton.small(
            heroTag: 'add',
            tooltip: l.actionAdd,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
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
            child: const Icon(Icons.document_scanner_outlined),
          ),
        ],
      ),
    );
  }

  Future<void> _scan(BuildContext context) async {
    final session = await Navigator.of(context).push<ScanSession>(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (session == null || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditDocumentScreen(session: session),
      ),
    );
  }

  Future<void> _showPendingReminders(BuildContext context, WidgetRef ref) async {
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
              ...pending.take(8).map(
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
  const _Wallet({required this.documents});

  final List<TrackedDocument> documents;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final needsAttention =
        documents.where((d) => d.status() != DocumentStatus.valid).toList();
    final rest =
        documents.where((d) => d.status() == DocumentStatus.valid).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
      children: [
        if (needsAttention.isNotEmpty) ...[
          _SectionHeader(l.homeNeedsAttention),
          ...needsAttention.map((d) => _WalletEntry(document: d)),
          const SizedBox(height: 20),
        ],
        if (rest.isNotEmpty) ...[
          _SectionHeader(l.homeEverythingElse),
          ...rest.map((d) => _WalletEntry(document: d)),
        ],
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

/// One document: its card face, with the urgency read underneath.
///
/// The status line sits below the card rather than on it. The card is the
/// document as it exists in the world; the countdown is Elapsa's opinion about
/// it, and conflating the two makes the card look like something official it
/// is not.
class _WalletEntry extends StatelessWidget {
  const _WalletEntry({required this.document});

  final TrackedDocument document;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final palette = StatusPalette.from(context);
    final status = document.status();
    final colour = palette.of(status);
    final days = document.daysRemaining();

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => EditDocumentScreen(existing: document),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                DocumentCardFace(document: document, compact: true),
                if (document.imageCount > 1)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.collections_outlined,
                              size: 11, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            '${document.imageCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                document.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colour.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      status.label(l).toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colour,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusLine(l, days),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            if (document.isTravelRestricted())
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 8),
                child: Row(
                  children: [
                    Icon(Icons.flight_takeoff,
                        size: 13, color: palette.critical),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l.travelRuleBadge,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: palette.critical,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _statusLine(L l, int days) {
    if (days < 0) return l.daysAgo(-days);
    if (document.status() == DocumentStatus.actionNeeded) {
      return '${l.daysLeft(days)} · ${l.startRenewingNow}';
    }
    return l.daysLeft(days);
  }
}

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
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: muted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
