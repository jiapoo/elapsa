import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elapsa/core/theme.dart';
import 'package:elapsa/data/document_repository.dart';
import 'package:elapsa/domain/document.dart';
import 'package:elapsa/ui/edit/edit_document_screen.dart';
import 'package:elapsa/ui/widgets/document_card_face.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(documentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elapsa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Scheduled reminders',
            onPressed: () => _showPendingReminders(context, ref),
          ),
        ],
      ),
      body: documents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load documents.\n$e')),
        data: (docs) =>
            docs.isEmpty ? const _EmptyState() : _Wallet(documents: docs),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const EditDocumentScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add document'),
      ),
    );
  }

  Future<void> _showPendingReminders(BuildContext context, WidgetRef ref) async {
    final pending = await ref.read(notificationServiceProvider).pending();
    if (!context.mounted) return;

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
                '${pending.length} reminder${pending.length == 1 ? '' : 's'} scheduled',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                pending.isEmpty
                    ? 'Add a document and Elapsa will schedule reminders for it.'
                    : 'These fire even if the app is never opened.',
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
    final needsAttention =
        documents.where((d) => d.status() != DocumentStatus.valid).toList();
    final rest =
        documents.where((d) => d.status() == DocumentStatus.valid).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        if (needsAttention.isNotEmpty) ...[
          const _SectionHeader('Needs attention'),
          ...needsAttention.map((d) => _WalletEntry(document: d)),
          const SizedBox(height: 20),
        ],
        if (rest.isNotEmpty) ...[
          const _SectionHeader('Everything else'),
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
            DocumentCardFace(document: document, compact: true),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                document.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
                      statusLabel(status).toUpperCase(),
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
                      _statusLine(days),
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
                    Text(
                      'Below the 6-month travel rule',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: palette.critical,
                            fontWeight: FontWeight.w600,
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

  String _statusLine(int days) {
    if (days < 0) return '${-days} days ago';
    if (document.status() == DocumentStatus.actionNeeded) {
      return '$days days left · start renewing now';
    }
    return '$days days left';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
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
              'Nothing expiring',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              'Add a passport, ID or licence and Elapsa will tell you when to '
              'start renewing it — not when it is already too late.',
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
