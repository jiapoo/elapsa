import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:elapsa/core/labels.dart';
import 'package:elapsa/core/theme.dart';
import 'package:elapsa/data/document_repository.dart';
import 'package:elapsa/domain/document.dart';
import 'package:elapsa/domain/document_type.dart';
import 'package:elapsa/l10n/app_localizations.dart';

/// Identifies one picture belonging to one document.
class DocumentImageRef {
  final String documentId;
  final int index;

  const DocumentImageRef(this.documentId, this.index);

  @override
  bool operator ==(Object other) =>
      other is DocumentImageRef &&
      other.documentId == documentId &&
      other.index == index;

  @override
  int get hashCode => Object.hash(documentId, index);
}

/// Decrypted bytes for one picture, or null when there is none.
///
/// Cached by Riverpod per reference so scrolling a list does not decrypt the
/// same photo on every frame.
final documentImageProvider =
    FutureProvider.family<Uint8List?, DocumentImageRef>((ref, image) async {
      return ref
          .watch(documentImageStoreProvider)
          .load(image.documentId, image.index);
    });

/// The visual representation of a document.
///
/// Shows the user's own photo when one was captured — that is the only honest
/// way to make a card look like the real thing — and otherwise a designed face
/// built from the scanned data. Elapsa never synthesises a replica of official
/// document artwork.
class DocumentCardFace extends ConsumerWidget {
  const DocumentCardFace({
    super.key,
    required this.document,
    this.page = 0,
    this.compact = false,
  });

  final TrackedDocument document;

  /// Which picture to show. 0 is the face shown in the wallet.
  final int page;

  /// Shrinks the type scale for list use.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = document.imageCount > page
        ? ref.watch(documentImageProvider(DocumentImageRef(document.id, page)))
        : const AsyncValue<Uint8List?>.data(null);
    final bytes = image.asData?.value;

    return AspectRatio(
      aspectRatio: kCardAspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 14 : 20),
        // A real card shows itself. The document already prints its own name,
        // number and expiry, so overlaying ours duplicates the information and
        // forces a heavy scrim over the very thing the user wanted to see.
        // Elapsa's own read on the document lives beneath the card instead.
        child: bytes != null
            ? Image.memory(bytes, fit: BoxFit.cover)
            : Stack(
                fit: StackFit.expand,
                children: [
                  _DesignedFace(type: document.type),
                  _CardText(document: document, compact: compact),
                ],
              ),
      ),
    );
  }
}

/// The fallback face, used until the user captures a photo.
///
/// Colour is derived from the document type so a wallet of several documents
/// is scannable at a glance, the way real cards are told apart by colour long
/// before anyone reads them.
class _DesignedFace extends StatelessWidget {
  const _DesignedFace({required this.type});

  final DocumentType type;

  static const _gradients = {
    DocumentType.passport: [Color(0xFF7A0F26), Color(0xFFDD1B3F)],
    DocumentType.nationalId: [Color(0xFF243B55), Color(0xFF3B5F82)],
    DocumentType.driversLicence: [Color(0xFF4A3A22), Color(0xFF7A5C33)],
    DocumentType.visa: [Color(0xFF3A2A4D), Color(0xFF5C4380)],
    DocumentType.residencePermit: [Color(0xFF13383D), Color(0xFF1F5F66)],
    DocumentType.vehicleRegistration: [Color(0xFF3E2F2F), Color(0xFF614A4A)],
    DocumentType.insurance: [Color(0xFF1E3A34), Color(0xFF326B5C)],
    DocumentType.professionalLicence: [Color(0xFF33304D), Color(0xFF524D7A)],
    DocumentType.membership: [Color(0xFF2E3B2E), Color(0xFF4C6146)],
    DocumentType.bankCard: [Color(0xFF262626), Color(0xFF454545)],
    DocumentType.other: [Color(0xFF33302F), Color(0xFF565150)],
  };

  @override
  Widget build(BuildContext context) {
    final colours = _gradients[type] ?? _gradients[DocumentType.other]!;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colours,
        ),
      ),
      child: Stack(
        children: [
          // Oversized, cropped type mark — a graphic device rather than an
          // icon, so it reads as card art instead of a placeholder.
          Positioned(
            right: -26,
            top: -18,
            child: Icon(
              type.icon,
              size: 148,
              color: Colors.white.withValues(alpha: 0.09),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardText extends StatelessWidget {
  const _CardText({required this.document, required this.compact});

  final TrackedDocument document;
  final bool compact;

  /// Shows only the last four characters.
  ///
  /// A card face is the one screen someone is likely to hold up in public, and
  /// the full number is never what they need to see at a glance.
  static String _mask(String number) {
    final trimmed = number.trim();
    if (trimmed.length <= 4) return trimmed;
    return '•••• ${trimmed.substring(trimmed.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final number = document.documentNumber;
    final holder = document.holder;
    final padding = compact ? 14.0 : 20.0;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (document.issuingCountry != null)
                _Pill(text: document.issuingCountry!),
              const Spacer(),
              _Pill(text: document.type.label(l).toUpperCase()),
            ],
          ),
          const Spacer(),
          Text(
            document.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 17 : 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          if (holder != null && holder.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              holder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: compact ? 12.5 : 14,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (number != null && number.isNotEmpty)
                Text(
                  _mask(number),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: compact ? 12 : 13.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: 0.5,
                  ),
                ),
              const Spacer(),
              _ExpiryStamp(document: document, compact: compact, l: l),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _ExpiryStamp extends StatelessWidget {
  const _ExpiryStamp({
    required this.document,
    required this.compact,
    required this.l,
  });

  final TrackedDocument document;
  final bool compact;
  final L l;

  @override
  Widget build(BuildContext context) {
    final endless = document.neverExpires;
    final expired = !endless && document.daysRemaining() < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          (expired ? l.statusExpired : l.fieldExpiry).toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          // The stored date is meaningless on a document with no end, and
          // printing it on the face of the card is the one place it would be
          // read as the answer rather than as leftovers.
          endless
              ? l.fieldNeverExpires
              : DateFormat.yMMM(Localizations.localeOf(context).toLanguageTag())
                    .format(document.expiryDate),
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 13 : 15,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
