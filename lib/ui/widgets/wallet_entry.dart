import 'package:flutter/material.dart';

import 'package:elapsa/core/labels.dart';
import 'package:elapsa/core/theme.dart';
import 'package:elapsa/data/settings_repository.dart';
import 'package:elapsa/domain/document.dart';
import 'package:elapsa/l10n/app_localizations.dart';
import 'package:elapsa/ui/detail/document_detail_screen.dart';
import 'package:elapsa/ui/widgets/document_card_face.dart';

/// One section of the wallet, in the order the user asked for.
///
/// Shared with the transfer picker: choosing what to send should look like
/// looking at the wallet, because that is what it is.
List<TrackedDocument> orderedWallet(
  List<TrackedDocument> documents,
  DocumentSort sort,
  L l,
) {
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
        final byType = a.typeLabel(l).compareTo(b.typeLabel(l));
        return byType != 0 ? byType : a.expiryDate.compareTo(b.expiryDate);
      });
  }
  return sorted;
}

class WalletEntry extends StatelessWidget {
  const WalletEntry({super.key, required this.document, required this.display});

  final TrackedDocument document;
  final WalletDisplay display;

  @override
  Widget build(BuildContext context) {
    // The detail page, not the form. Checking when a passport expires should
    // not put anyone in front of fifteen fields and a Save button.
    void open() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DocumentDetailScreen(id: document.id),
      ),
    );

    final child = switch (display) {
      WalletDisplay.imageOnly => _Tile(document: document),
      WalletDisplay.nameAndImage => _Row(document: document),
      WalletDisplay.nameOnly => _Listed(document: document),
    };

    return Padding(
      // The grid does its own spacing; a column has to bring its own.
      padding: EdgeInsets.only(
        bottom: display == WalletDisplay.imageOnly ? 0 : 10,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: open,
        child: child,
      ),
    );
  }
}

/// A thumbnail with the reading beside it.
///
/// The card used to run the full width of the screen, which showed perhaps two
/// documents at a time — handsome, and useless for the thing a wallet is for,
/// which is finding one document among many. At this size the picture is still
/// what you recognise it by, and five or six fit on a screen.
class _Row extends StatelessWidget {
  const _Row({required this.document});

  final TrackedDocument document;

  static const _thumbWidth = 118.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _thumbWidth,
            child: Stack(
              children: [
                DocumentCardFace(document: document, compact: true),
                if (document.imageCount > 1)
                  Positioned(
                    right: 5,
                    bottom: 5,
                    child: _PageCount(count: document.imageCount),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  document.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                _Status(document: document, compact: true),
                if (document.isTravelRestricted()) ...[
                  const SizedBox(height: 6),
                  const _TravelWarning(),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// The picture alone, in a grid two across.
///
/// No text at all, so the urgency has to be carried on the card. A small pill
/// in the corner does it without turning the picture into a dashboard.
class _Tile extends StatelessWidget {
  const _Tile({required this.document});

  final TrackedDocument document;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final status = document.status();
    final colour = StatusPalette.from(context).of(status);
    final days = document.daysRemaining();

    return Stack(
      children: [
        Positioned.fill(
          child: DocumentCardFace(document: document, compact: true),
        ),
        Positioned(
          left: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: colour,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              days < 0
                  ? l.shortExpired
                  : compactDuration(DateTime.now(), document.expiryDate, l),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
        if (document.imageCount > 1)
          Positioned(
            right: 8,
            bottom: 8,
            child: _PageCount(count: document.imageCount),
          ),
        if (document.isTravelRestricted())
          Positioned(
            right: 8,
            top: 8,
            child: Icon(
              Icons.flight_takeoff_rounded,
              size: 14,
              color: StatusPalette.from(context).critical,
            ),
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
                  walletStatusLine(document, l),
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
              Icons.flight_takeoff_rounded,
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
  const _Status({required this.document, this.compact = false});

  final TrackedDocument document;

  /// Stacks the badge above the countdown instead of beside it, for the
  /// narrow column next to a thumbnail.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final status = document.status();
    final colour = StatusPalette.from(context).of(status);

    final badge = Container(
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
    );

    final line = Text(
      walletStatusLine(document, l),
      maxLines: compact ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [badge, const SizedBox(height: 5), line],
      );
    }

    return Row(
      children: [
        badge,
        const SizedBox(width: 10),
        Expanded(child: line),
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
          const Icon(Icons.collections_rounded, size: 11, color: Colors.white),
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
        Icon(Icons.flight_takeoff_rounded, size: 13, color: critical),
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

String walletStatusLine(TrackedDocument document, L l) {
  final today = DateTime.now();
  final expiry = document.expiryDate;

  if (document.daysRemaining() < 0) {
    return l.durationAgo(durationLabel(expiry, today, l));
  }

  final left = l.durationLeft(durationLabel(today, expiry, l));
  if (document.status() == DocumentStatus.actionNeeded) {
    return '$left · ${l.startRenewingNow}';
  }
  return left;
}
