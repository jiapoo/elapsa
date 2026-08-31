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
  List<TrackedDocument> _ordered(List<TrackedDocument> documents, L l) {
    final sorted = [...documents];
    switch (sort) {
      case DocumentSort.expiry:
        sorted.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      case DocumentSort.added:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case DocumentSort.name:
        sorted.sort((a, b) {
          final byName = a.label.toLowerCase().compareTo(b.label.toLowerCase());
          return byName != 0 ? byName : a.expiryDate.compareTo(b.expiryDate);
        });
      case DocumentSort.type:
        sorted.sort((a, b) {
          final byType = a.type.label(l).compareTo(b.type.label(l));
          return byType != 0 ? byType : a.expiryDate.compareTo(b.expiryDate);
        });
    }
    return sorted;
  }

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

    // Without pictures the entries are single rows, and the generous spacing
    // that a wall of cards needs turns into a list adrift on the page.
    final dense = !display.showsImage;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, dense ? 120 : 140),
      children: [
        if (needsAttention.isNotEmpty) ...[
          _SectionHeader(l.homeNeedsAttention),
          ...needsAttention.map(
            (d) => _WalletEntry(document: d, display: display),
          ),
          SizedBox(height: dense ? 24 : 20),
        ],
        if (rest.isNotEmpty) ...[
          _SectionHeader(l.homeEverythingElse),
          ...rest.map((d) => _WalletEntry(document: d, display: display)),
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

/// One document, at whichever density the user asked for.
///
/// The status line always survives. Whatever else is hidden, an app whose
/// entire purpose is telling you when to start renewing cannot show a list
/// that does not say.
class _WalletEntry extends StatelessWidget {
  const _WalletEntry({required this.document, required this.display});

  final TrackedDocument document;
  final WalletDisplay display;

  @override
  Widget build(BuildContext context) {
    void open() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditDocumentScreen(existing: document),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: display.showsImage ? 22 : 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: open,
        child: display.showsImage
            ? _Framed(document: document, withName: display.showsName)
            : _Listed(document: document),
      ),
    );
  }
}

/// The picture, full width, with as much or as little written under it as the
/// display mode allows.
class _Framed extends StatelessWidget {
  const _Framed({required this.document, required this.withName});

  final TrackedDocument document;
  final bool withName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            DocumentCardFace(document: document, compact: true),
            if (document.imageCount > 1)
              Positioned(
                right: 10,
                bottom: 10,
                child: _PageCount(count: document.imageCount),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (withName) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              document.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _Status(document: document),
        ),
        if (document.isTravelRestricted())
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 8),
            child: _TravelWarning(),
          ),
      ],
    );
  }
}

/// One row: the type's mark, the name, and the countdown.
///
/// No photograph at all — which is the point of the mode. A document is the
/// one thing on a phone you might not want rendered life-size on a screen
/// somebody else can see.
class _Listed extends StatelessWidget {
  const _Listed({required this.document});

  final TrackedDocument document;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final colour = StatusPalette.from(context).of(document.status());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // A stripe rather than a badge: it reads as urgency at the edge of
          // vision, in a row that is otherwise all text.
          Container(
            width: 3,
            height: 34,
            decoration: BoxDecoration(
              color: colour,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Icon(document.type.icon, size: 19, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  _statusLine(document, l),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (document.isTravelRestricted()) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.flight_takeoff,
              size: 15,
              color: StatusPalette.from(context).critical,
            ),
          ],
        ],
      ),
    );
  }
}

/// The urgency read: Elapsa's opinion, kept off the card itself.
///
/// The card is the document as it exists in the world; the countdown is what
/// this app thinks about it, and conflating the two makes the card look like
/// something official it is not.
class _Status extends StatelessWidget {
  const _Status({required this.document});

  final TrackedDocument document;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final status = document.status();
    final colour = StatusPalette.from(context).of(status);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            _statusLine(document, l),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _PageCount extends StatelessWidget {
  const _PageCount({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.collections_outlined, size: 11, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelWarning extends StatelessWidget {
  const _TravelWarning();

  @override
  Widget build(BuildContext context) {
    final critical = StatusPalette.from(context).critical;

    return Row(
      children: [
        Icon(Icons.flight_takeoff, size: 13, color: critical),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            L.of(context).travelRuleBadge,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: critical, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

String _statusLine(TrackedDocument document, L l) {
  final days = document.daysRemaining();
  if (days < 0) return l.daysAgo(-days);
  if (document.status() == DocumentStatus.actionNeeded) {
    return '${l.daysLeft(days)} · ${l.startRenewingNow}';
  }
  return l.daysLeft(days);
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
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: muted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
