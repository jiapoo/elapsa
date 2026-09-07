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
                  _CardText(document: document),
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
  const _CardText({required this.document});

  final TrackedDocument document;

  /// Shows only the last four characters.
  ///
  /// A card face is the one screen someone is likely to hold up in public, and
  /// the full number is never what they need to see at a glance.
  static String _mask(String number) {
    final trimmed = number.trim();
    if (trimmed.length <= 4) return trimmed;
    return '•••• ${trimmed.substring(trimmed.length - 4)}';
  }

  /// The width this face was designed at. Everything is a fraction of it.
  static const _reference = 350.0;

  /// Below this there is room for a mark and a name and nothing else.
  static const _tiny = 210.0;

  @override
  Widget build(BuildContext context) {
    // Measured, not guessed.
    //
    // This face used to size itself from a boolean — compact or not — chosen
    // by whichever screen was drawing it. Then the wallet's thumbnails got
    // smaller, and "compact" was still a card's worth of text in a space the
    // height of two lines: five rows of it, overflowing by sixty-one pixels,
    // on every document without a photograph. Nobody saw it because the
    // documents being tested all had photographs, and a photograph covers this
    // whole widget.
    //
    // A card is a fixed shape, so its width settles everything. Reading that
    // width means the face fits wherever it is put, including sizes nobody has
    // thought of yet.
    return LayoutBuilder(
      builder: (context, box) {
        final l = L.of(context);
        final scale = (box.maxWidth / _reference).clamp(0.3, 1.0);
        final padding = (20 * scale).clamp(7.0, 20.0);

        if (box.maxWidth < _tiny) {
          // A thumbnail. The type and the name are what tell one card from
          // another at this size; a masked number and a date are unreadable
          // and only crowd them out.
          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: _Pill(
                    text: document.type.label(l).toUpperCase(),
                    scale: scale,
                  ),
                ),
                const Spacer(),
                Text(
                  document.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (22 * scale).clamp(10.0, 22.0),
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          );
        }

        final number = document.documentNumber;
        final holder = document.holder;

        return Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (document.issuingCountry != null)
                    _Pill(text: document.issuingCountry!, scale: scale),
                  const Spacer(),
                  _Pill(
                    text: document.type.label(l).toUpperCase(),
                    scale: scale,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                document.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22 * scale,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              if (holder != null && holder.isNotEmpty) ...[
                SizedBox(height: 2 * scale),
                Text(
                  holder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 14 * scale,
                  ),
                ),
              ],
              SizedBox(height: 10 * scale),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (number != null && number.isNotEmpty)
                    Flexible(
                      child: Text(
                        _mask(number),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 13.5 * scale,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  const Spacer(),
                  _ExpiryStamp(document: document, scale: scale, l: l),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExpiryStamp extends StatelessWidget {
  const _ExpiryStamp({
    required this.document,
    required this.scale,
    required this.l,
  });

  final TrackedDocument document;
  final double scale;
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
            fontSize: 8.5 * scale,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1 * scale,
          ),
        ),
        SizedBox(height: 1 * scale),
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
            fontSize: 15 * scale,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// A small label on the card's own artwork — a country code, a type.
class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.scale});

  final String text;

  /// How large this face is being drawn, relative to full size.
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (8 * scale).clamp(4.0, 8.0),
        vertical: (3 * scale).clamp(1.5, 3.0),
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: (9.5 * scale).clamp(6.5, 9.5),
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0 * scale,
        ),
      ),
    );
  }
}
