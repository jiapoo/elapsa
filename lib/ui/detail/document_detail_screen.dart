import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:elapsa/core/labels.dart';
import 'package:elapsa/core/theme.dart';
import 'package:elapsa/data/document_repository.dart';
import 'package:elapsa/data/settings_repository.dart';
import 'package:elapsa/domain/document.dart';
import 'package:elapsa/domain/document_detail.dart';
import 'package:elapsa/l10n/app_localizations.dart';
import 'package:elapsa/services/attachment_store.dart';
import 'package:elapsa/ui/edit/edit_document_screen.dart';
import 'package:elapsa/ui/scan/scan_screen.dart';
import 'package:elapsa/ui/widgets/attachments_section.dart';
import 'package:elapsa/ui/widgets/picture_sheet.dart';
import 'package:elapsa/ui/widgets/document_card_face.dart';

/// One document, to look at rather than to change.
///
/// Opening straight into a form made every glance an edit: to check when a
/// passport expires you were put in front of fifteen fields, a keyboard and a
/// Save button, with no way to tell whether you had touched anything. Reading
/// and editing are different errands, and reading is by far the commoner one.
class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({super.key, required this.id});

  /// Looked up by id rather than held, so an edit made on the next screen is
  /// visible the moment it is saved.
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final documents = ref.watch(documentsProvider).asData?.value ?? const [];
    final document = documents.where((d) => d.id == id).firstOrNull;

    if (document == null) {
      // Deleted from the screen above this one. Nothing to say about it.
      return Scaffold(appBar: AppBar(title: Text(l.detailTitle)));
    }

    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final palette = StatusPalette.from(context);
    final colour = palette.of(document.status());
    final custom = ref
        .watch(customTypesProvider)
        .where((t) => t.name == document.customType)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.detailTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => EditDocumentScreen(existing: document),
              ),
            ),
            child: Text(l.actionEdit),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          if (document.imageCount > 0)
            _Pages(document: document)
          else
            DocumentCardFace(document: document),

          const SizedBox(height: 22),

          Text(
            document.label,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                custom?.glyph ?? document.type.icon,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Text(
                document.customType ?? document.type.label(l),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (document.imageCount > 1) ...[
                Text('  ·  ', style: TextStyle(color: scheme.onSurfaceVariant)),
                Text(
                  l.detailPages(document.imageCount),
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // The countdown, given the room it deserves. This is the one thing
          // the app exists to tell anyone, and on the wallet it is a line of
          // small print under a picture.
          _Countdown(document: document, colour: colour),

          const SizedBox(height: 12),

          _Facts(
            children: [
              if (!document.neverExpires)
                _Fact(
                  label: l.fieldExpiry,
                  value: DateFormat.yMMMMd(locale).format(document.expiryDate),
                ),
              if (document.issueDate != null)
                _Fact(
                  label: l.fieldIssueDate,
                  value: DateFormat.yMMMMd(locale).format(document.issueDate!),
                ),
              if (document.documentNumber != null)
                _Fact(
                  label: documentNumberLabel(l, document.type),
                  value: document.documentNumber!,
                  monospaced: true,
                ),
              if (document.holder != null && document.holder!.isNotEmpty)
                _Fact(label: l.fieldHolderHint, value: document.holder!),
              if (document.issuingCountry != null)
                // Not "nationality": that is a field of its own, and a
                // passport carries both — so labelling this one nationality
                // too printed the word twice with different answers under it.
                _Fact(label: l.detailIssuedBy, value: document.issuingCountry!),
              for (final detail in DocumentDetail.values)
                if (document.details[detail] != null)
                  _Fact(
                    label: detail.label(l),
                    value: document.details[detail]!,
                    secret: detail.isSensitive,
                    monospaced: detail.isSensitive,
                  ),
              // The user's own, last and in their own order — they were added
              // to say something this app did not think to ask.
              for (final field in document.extras.entries)
                if (field.value.isNotEmpty)
                  _Fact(label: field.key, value: field.value),
            ],
          ),

          if (document.attachments.isNotEmpty) ...[
            const SizedBox(height: 22),
            _Attachments(document: document),
          ],

          const SizedBox(height: 22),
          _Reminders(document: document),

          if (document.isTravelRestricted()) ...[
            const SizedBox(height: 18),
            _Warning(text: l.travelRuleBadge, colour: palette.critical),
          ],
        ],
      ),
    );
  }
}

/// Every picture, swipeable, with the position marked.
///
/// Tapping one offers what can be done with it without going into the editor:
/// a better photograph, or a copy kept somewhere else.
class _Pages extends ConsumerStatefulWidget {
  const _Pages({required this.document});

  final TrackedDocument document;

  @override
  ConsumerState<_Pages> createState() => _PagesState();
}

class _PagesState extends ConsumerState<_Pages> {
  final _controller = PageController();
  int _page = 0;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _options(int page) async {
    if (_busy) return;
    final document = widget.document;
    final image = await ref.read(
      documentImageProvider(DocumentImageRef(document.id, page)).future,
    );
    if (image == null || !mounted) return;

    final choice = await showPictureSheet(
      context,
      image: image,
      actions: const [
        PictureAction.retake,
        PictureAction.saveToPhotos,
        PictureAction.saveToFiles,
      ],
    );
    if (choice == null || !mounted) return;

    switch (choice) {
      case PictureAction.retake:
        await _retake(page);
      case PictureAction.saveToPhotos:
        await savePictureToPhotos(context, image);
      case PictureAction.saveToFiles:
        await savePictureToFiles(
          context,
          image,
          baseName: document.imageCount > 1
              ? '${document.label} ${page + 1}'
              : document.label,
        );
      case PictureAction.crop || PictureAction.delete:
        break;
    }
  }

  /// Replaces one picture with a new photograph, in the same place.
  ///
  /// Only the picture changes. Reading the fields again is the editor's job,
  /// where the user can see what changed; here they asked for a better photo
  /// of a document they were only looking at.
  Future<void> _retake(int page) async {
    final session = await Navigator.of(context).push<ScanSession>(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (session == null || session.images.isEmpty || !mounted) return;

    setState(() => _busy = true);
    try {
      final document = widget.document;
      final images = await ref
          .read(documentImageStoreProvider)
          .loadAll(document.id, document.imageCount);
      if (page < images.length) images.removeAt(page);
      images.insertAll(page.clamp(0, images.length), session.images);

      await ref.read(documentRepositoryProvider).setImages(document, images);
      final pages = images.length > document.imageCount
          ? images.length
          : document.imageCount;
      for (var i = 0; i < pages; i++) {
        ref.invalidate(documentImageProvider(DocumentImageRef(document.id, i)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = widget.document.imageCount;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: kCardAspectRatio,
          child: PageView.builder(
            controller: _controller,
            itemCount: count,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, page) => GestureDetector(
              onTap: () => _options(page),
              child: DocumentCardFace(document: widget.document, page: page),
            ),
          ),
        ),
        if (count > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < count; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? scheme.primary : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The files and links kept with this document.
class _Attachments extends ConsumerStatefulWidget {
  const _Attachments({required this.document});

  final TrackedDocument document;

  @override
  ConsumerState<_Attachments> createState() => _AttachmentsState();
}

class _AttachmentsState extends ConsumerState<_Attachments> {
  late final AttachmentStore _store = ref.read(attachmentStoreProvider);

  @override
  void dispose() {
    // Whatever was decrypted for viewing goes when the document is closed.
    _store.clearOpened();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            L.of(context).attachmentsTitle.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1.1,
            ),
          ),
        ),
        AttachmentsSection(
          attachments: widget.document.attachments,
          onOpen: (attachment) => openAttachment(
            context,
            ref,
            documentId: widget.document.id,
            attachment: attachment,
          ),
        ),
      ],
    );
  }
}

/// How long is left, said once and said largely.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.document, required this.colour});

  final TrackedDocument document;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final status = document.status();
    final expired = !document.neverExpires && document.daysRemaining() < 0;
    final now = DateTime.now();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Radii.panel),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status.label(l).toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colour,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            document.neverExpires
                ? l.fieldNeverExpires
                : expired
                ? durationLabel(document.expiryDate, now, l)
                : durationLabel(now, document.expiryDate, l),
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: colour, fontSize: 26, letterSpacing: -0.6),
          ),
          if (!document.neverExpires &&
              (status == DocumentStatus.actionNeeded ||
                  status == DocumentStatus.critical)) ...[
            const SizedBox(height: 4),
            Text(
              l.startRenewingNow,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colour),
            ),
          ],
        ],
      ),
    );
  }
}

/// The document's own particulars, in one panel.
class _Facts extends StatelessWidget {
  const _Facts({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Radii.panel),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 16, color: scheme.outlineVariant),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Fact extends StatefulWidget {
  const _Fact({
    required this.label,
    required this.value,
    this.secret = false,
    this.monospaced = false,
  });

  final String label;
  final String value;
  final bool secret;
  final bool monospaced;

  @override
  State<_Fact> createState() => _FactState();
}

class _FactState extends State<_Fact> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    // Hidden until asked for. This screen is the one somebody holds up to show
    // a colleague which card they mean.
    final hide = widget.secret && !_shown;

    return InkWell(
      // Held down to copy. A document number exists to be typed into
      // somewhere else, and reading it off a screen digit by digit is how it
      // gets typed in wrong.
      onLongPress: hide
          ? null
          : () async {
              await Clipboard.setData(ClipboardData(text: widget.value));
              if (!context.mounted) return;
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(l.settingsCopied)));
            },
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 14, widget.secret ? 6 : 16, 14),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                widget.label,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            Expanded(
              flex: 6,
              child: Align(
                alignment: Alignment.centerRight,
                // Shrunk to fit rather than wrapped. A card number broken over
                // two lines stops being a number you can read against the card
                // in your hand — the grouping is what makes it checkable, and a
                // line break in the middle of it destroys that.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    hide ? '••••••' : widget.value,
                    maxLines: 1,
                    softWrap: false,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: widget.monospaced
                          ? const [FontFeature.tabularFigures()]
                          : null,
                      letterSpacing: widget.monospaced ? 0.4 : null,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.secret)
              IconButton(
                iconSize: 19,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  _shown
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: scheme.onSurfaceVariant,
                ),
                tooltip: _shown ? l.detailHide : l.detailReveal,
                onPressed: () => setState(() => _shown = !_shown),
              ),
          ],
        ),
      ),
    );
  }
}

/// When this document will next speak up.
class _Reminders extends StatelessWidget {
  const _Reminders({required this.document});

  final TrackedDocument document;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dates = document.reminderDates();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.notifications_active_rounded,
          size: 17,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.detailReminders,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 3),
              Text(
                dates.isEmpty
                    ? l.detailNoReminders
                    : l.detailNextReminder(
                        DateFormat.yMMMd(locale).format(dates.first),
                      ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.text, required this.colour});

  final String text;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(Radii.control),
      ),
      child: Row(
        children: [
          Icon(Icons.flight_takeoff_rounded, size: 17, color: colour),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colour),
            ),
          ),
        ],
      ),
    );
  }
}
