import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:elapsa/core/card_number.dart';
import 'package:elapsa/core/labels.dart';
import 'package:elapsa/core/theme.dart';
import 'package:elapsa/data/document_repository.dart';
import 'package:elapsa/data/settings_repository.dart';
import 'package:elapsa/domain/document.dart';
import 'package:elapsa/domain/document_detail.dart';
import 'package:elapsa/domain/document_type.dart';
import 'package:elapsa/l10n/app_localizations.dart';

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:elapsa/services/vision_channel.dart';
import 'package:elapsa/ui/scan/crop_screen.dart';
import 'package:elapsa/ui/scan/scan_screen.dart';
import 'package:elapsa/ui/widgets/document_card_face.dart';

class EditDocumentScreen extends ConsumerStatefulWidget {
  const EditDocumentScreen({super.key, this.existing, this.session});

  final TrackedDocument? existing;

  /// A scan the user just made, if they arrived here from the scanner.
  final ScanSession? session;

  @override
  ConsumerState<EditDocumentScreen> createState() => _EditDocumentScreenState();
}

class _EditDocumentScreenState extends ConsumerState<EditDocumentScreen> {
  final _formKey = GlobalKey<FormState>();

  late DocumentType _type;
  late TextEditingController _label;
  late TextEditingController _holder;
  late TextEditingController _documentNumber;
  DateTime? _expiryDate;
  DateTime? _issueDate;
  late Set<int> _reminderOffsets;
  String? _issuingCountry;

  /// One controller per detail, kept for every kind of document rather than
  /// just the current one. Switching type to look at the options and switching
  /// back should not quietly discard what was already typed.
  final _details = <DocumentDetail, TextEditingController>{};

  /// Which sensitive values the user has chosen to reveal, this session only.
  final _revealed = <DocumentDetail>{};

  /// Pictures from this session. Empty on an edit means "leave what is stored
  /// alone" — only a fresh scan replaces them.
  final _images = <Uint8List>[];

  bool _fromScan = false;

  /// Whether the editing list holds the document's whole set of pictures, and
  /// so can be written back over it.
  bool _imagesLoaded = false;

  /// Set when a picture is moved or cropped. The list is the same length
  /// afterwards, so nothing else would notice it had changed.
  bool _imagesChanged = false;

  /// Whether the scan actually yielded any field, as opposed to only a
  /// picture. Claiming "filled in from the document" over an empty form is
  /// worse than saying nothing.
  bool _readAnything = false;

  /// True until the user edits the lead time by hand, after which changing the
  /// document type no longer overwrites their choice.
  bool _leadDaysIsAuto = true;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _type = existing?.type ?? DocumentType.passport;
    _label = TextEditingController(text: existing?.label ?? '');
    _holder = TextEditingController(text: existing?.holder ?? '');
    _documentNumber = TextEditingController(
      text: existing == null
          ? ''
          : existing.type == DocumentType.bankCard
          ? groupCardNumber(existing.documentNumber ?? '')
          : existing.documentNumber ?? '',
    );
    _expiryDate = existing?.expiryDate;
    _issueDate = existing?.issueDate;
    _issuingCountry = existing?.issuingCountry;
    _reminderOffsets = {
      ...(existing?.reminderOffsetDays ??
          _defaultOffsets(_type.defaultRenewalLeadDays)),
    };
    _leadDaysIsAuto = existing == null || !existing.hasChosenReminders;

    for (final detail in DocumentDetail.values) {
      _details[detail] = TextEditingController(
        text: existing?.details[detail] ?? '',
      );
    }

    final existingImages = widget.existing;
    if (existingImages != null && existingImages.imageCount > 0) {
      _loadStoredImages(existingImages);
    }

    final session = widget.session;
    if (session != null) {
      // Deferred, because filling the form needs the localisations that are
      // only available once there is a context.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _applySession(session),
      );
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _holder.dispose();
    _documentNumber.dispose();
    for (final controller in _details.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Offers what to do with a picture the user tapped.
  ///
  /// A sheet rather than a dialog, showing the picture itself: three unlabelled
  /// thumbnails in a row look much alike, and being asked "delete this one?"
  /// over a covered-up strip is a good way to lose the wrong photograph.
  Future<void> _pictureOptions(int index) async {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;

    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: scheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: kCardAspectRatio,
                  child: Image.memory(_images[index], fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 20),
              _SheetAction(
                icon: Icons.crop,
                label: l.actionCrop,
                onTap: () => Navigator.of(context).pop('crop'),
              ),
              _SheetAction(
                icon: Icons.photo_camera_outlined,
                label: l.actionRetake,
                onTap: () => Navigator.of(context).pop('retake'),
              ),
              _SheetAction(
                icon: Icons.delete_outline,
                label: l.actionDelete,
                colour: scheme.error,
                onTap: () => Navigator.of(context).pop('delete'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(l.actionCancel),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;

    // Cropping changes the picture and nothing else. The form is the user's;
    // trimming a photograph is not new information about the document, and
    // silently rewriting fields they have already corrected would make the
    // safest of the three options the most destructive.
    if (choice == 'crop') {
      await _crop(index);
      return;
    }

    setState(() => _images.removeAt(index));
    if (choice == 'delete') return;

    // A retake replaces a picture, not the document. It still reads what it
    // can — a field left blank is worth filling from a better photograph —
    // but it will not overwrite an answer already on the form.
    await _scan(keepFilled: true);
  }

  /// Trims one picture, leaving every field exactly as it was.
  ///
  /// Cropping works from the stored picture rather than the original
  /// photograph, which is long gone by the time a document is opened again —
  /// so this trims what is there rather than re-cutting what it came from.
  Future<void> _crop(int index) async {
    File? temp;
    try {
      final dir = await getTemporaryDirectory();
      temp = File(
        p.join(
          dir.path,
          'elapsa-edit-${DateTime.now().microsecondsSinceEpoch}.jpg',
        ),
      );
      await temp.writeAsBytes(_images[index]);
      if (!mounted) return;

      final quad = await Navigator.of(context).push<CardQuad>(
        MaterialPageRoute(builder: (_) => CropScreen(imagePath: temp!.path)),
      );
      if (quad == null || !mounted) return;

      final cut = await const VisionChannel().extractCard(
        temp.path,
        quad: quad,
      );
      if (cut == null || !mounted) return;

      setState(() {
        _imagesChanged = true;
        _images[index] = cut.bytes;
      });
    } catch (error, stack) {
      debugPrint('Elapsa: cropping failed: $error\n$stack');
    } finally {
      // A decrypted picture of someone's document has no business outliving
      // the crop that needed it.
      if (temp != null && await temp.exists()) await temp.delete();
    }
  }

  /// Brings a saved document's pictures into the editing list.
  ///
  /// One list for everything means reordering, deleting and adding are the
  /// same operation whether the document has been saved before or not.
  Future<void> _loadStoredImages(TrackedDocument document) async {
    final loaded = await ref
        .read(documentImageStoreProvider)
        .loadAll(document.id, document.imageCount);
    if (!mounted || loaded.isEmpty) return;
    setState(() {
      _images
        ..clear()
        ..addAll(loaded);
      _imagesLoaded = true;
    });
  }

  /// Adds a reminder on a day the user chose outright.
  ///
  /// Stored as days before expiry like every other reminder, because that is
  /// what survives the expiry date being corrected afterwards — a date pinned
  /// to the calendar would quietly become nonsense the moment the document it
  /// belongs to moved.
  Future<void> _pickReminderDate() async {
    final expiry = _expiryDate;
    if (expiry == null) {
      final l = L.of(context);
      // A reminder is a number of days before the expiry; without one there
      // is nothing to count back from.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.fieldExpiryRequired)));
      return;
    }

    final today = DateTime.now();
    final earliest = DateTime(today.year, today.month, today.day);
    // No later than a month out, because everything inside that is reminded on
    // daily already and a chosen date there would change nothing.
    final latest = expiry.subtract(
      const Duration(days: TrackedDocument.dailyTailDays),
    );
    if (!latest.isAfter(earliest)) return;

    final chosen = await showDatePicker(
      context: context,
      firstDate: earliest,
      lastDate: latest,
      initialDate: latest,
    );
    if (chosen == null || !mounted) return;

    setState(() {
      _reminderOffsets.add(
        DateTime(
          expiry.year,
          expiry.month,
          expiry.day,
        ).difference(DateTime(chosen.year, chosen.month, chosen.day)).inDays,
      );
      _leadDaysIsAuto = false;
    });
  }

  Future<void> _scan({bool keepFilled = false}) async {
    final session = await Navigator.of(
      context,
    ).push<ScanSession>(MaterialPageRoute(builder: (_) => const ScanScreen()));
    if (session != null) _applySession(session, keepFilled: keepFilled);
  }

  /// Folds a scan into the form.
  ///
  /// A field the scan read replaces what is there; a field it read nothing for
  /// is left alone. That one rule covers both cases: retaking a picture fills
  /// the form in again from the better photograph, while adding the back of a
  /// card — which carries no number and no dates — cannot wipe what the front
  /// already gave.
  ///
  /// Everything stays editable afterwards. The check digits make a validated
  /// code near-certain to be right, but the user's own name for the document
  /// is theirs to choose, and a wrong guess should never be locked in.
  void _applySession(ScanSession session, {bool keepFilled = false}) {
    if (!mounted) return;
    final l = L.of(context);
    final mrz = session.mrz;

    /// Writes a field the scan read.
    ///
    /// With [keepFilled] it will not tread on a value that is already there.
    /// That is what a retake asks for: the picture is being replaced, not the
    /// document, and a field the user has corrected by hand should survive a
    /// second photograph of the same passport.
    void write(TextEditingController field, String? value) {
      if (value == null || value.isEmpty) return;
      if (keepFilled && field.text.trim().isNotEmpty) return;
      field.text = value;
    }

    bool free(Object? current) => !keepFilled || current == null;

    setState(() {
      _fromScan = true;
      _readAnything = mrz != null || !session.printed.isEmpty;
      // Append. "Add another side" opens a fresh scanner, so replacing here
      // would throw away every page captured before it.
      _images.addAll(session.images);

      // Printed fields first, so a validated MRZ can still override them.
      // Most documents have no MRZ at all — a Chinese 居民身份证 prints its
      // 有效期限 in plain sight and nothing else.
      final printed = session.printed;
      if (printed.type != null && !keepFilled) {
        _type = printed.type!;
        if (_leadDaysIsAuto) {
          _reminderOffsets = {..._defaultOffsets(_type.defaultRenewalLeadDays)};
        }
      }
      if (printed.expiryDate != null && free(_expiryDate)) {
        _expiryDate = printed.expiryDate;
      }
      if (printed.issueDate != null && free(_issueDate)) {
        _issueDate = printed.issueDate;
      }
      write(_details[DocumentDetail.securityCode]!, printed.securityCode);
      if (printed.holderName != null) {
        write(_details[DocumentDetail.cardholderName]!, printed.holderName);
        write(_holder, _titleCase(printed.holderName!));
      }
      if (printed.documentNumber != null) {
        write(
          _documentNumber,
          printed.type == DocumentType.bankCard
              ? groupCardNumber(printed.documentNumber!)
              : printed.documentNumber,
        );
      }
      write(_label, printed.issuer);

      if (mrz == null) {
        if (_label.text.trim().isEmpty) _label.text = _type.label(l);
        return;
      }

      final scannedType = _typeFromDocumentCode(mrz.documentCode);
      if (scannedType != null && !keepFilled) {
        _type = scannedType;
        if (_leadDaysIsAuto) {
          _reminderOffsets = {
            ..._defaultOffsets(scannedType.defaultRenewalLeadDays),
          };
        }
      }

      if (mrz.expiryDate != null && free(_expiryDate)) {
        _expiryDate = mrz.expiryDate;
      }
      write(_documentNumber, mrz.documentNumber);
      if (mrz.issuingState.isNotEmpty && free(_issuingCountry)) {
        _issuingCountry = mrz.issuingState;
      }
      if (mrz.fullName.isNotEmpty) write(_holder, _titleCase(mrz.fullName));
      if (_label.text.trim().isEmpty) _label.text = _type.label(l);
    });

    if (mrz != null && mrz.wasRepaired && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.editScanRepaired)));
    }
  }

  /// Maps the ICAO document code to a type we track.
  ///
  /// Returns null rather than guessing when the code is unfamiliar, leaving
  /// whatever the user already picked in place.
  static DocumentType? _typeFromDocumentCode(String code) {
    if (code.isEmpty) return null;
    return switch (code[0]) {
      'P' => DocumentType.passport,
      'V' => DocumentType.visa,
      'A' || 'C' || 'I' => DocumentType.nationalId,
      _ => null,
    };
  }

  /// MRZ names are upper case by definition; "ANNA MARIA ERIKSSON" shouted at
  /// the user in a form field looks like a bug.
  static String _titleCase(String value) => value
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0] + w.substring(1).toLowerCase())
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      // Intercepted rather than confirmed afterwards, because the swipe back
      // is a gesture people make without deciding anything, and it was quietly
      // throwing away a scan and every correction typed after it.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _mayLeave()) {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? l.editEditTitle : l.editAddTitle),
          titleTextStyle: Theme.of(context).textTheme.titleLarge,
          actions: [
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l.actionDelete,
                onPressed: _confirmDelete,
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              if (_images.isNotEmpty) ...[
                _Label(l.fieldImages),
                _CapturedPages(
                  images: _images,
                  onAdd: _scan,
                  onTapImage: _pictureOptions,
                  onReorder: (from, to) => setState(() {
                    _imagesChanged = true;
                    _images.insert(to, _images.removeAt(from));
                  }),
                ),
                const SizedBox(height: 24),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _scan,
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: Text(l.actionScan),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(color: scheme.outlineVariant),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    l.editScanHelp,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              if (_fromScan) ...[
                _InfoNote(
                  icon: Icons.verified_outlined,
                  text: _readAnything
                      ? l.editFromScanNote
                      : l.editScanNothingRead,
                ),
                const SizedBox(height: 24),
              ],

              _Label(l.fieldType),
              DropdownButtonFormField<DocumentType>(
                initialValue: _type,
                items: DocumentType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            Icon(t.icon, size: 18),
                            const SizedBox(width: 10),
                            Text(t.label(l)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _type = value;
                    if (_leadDaysIsAuto) {
                      _reminderOffsets = {
                        ..._defaultOffsets(value.defaultRenewalLeadDays),
                      };
                    }
                  });
                },
              ),
              const SizedBox(height: 20),

              _Label(l.fieldName),
              TextFormField(
                controller: _label,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: l.fieldNameHint(_type.label(l)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l.fieldNameRequired
                    : null,
              ),
              const SizedBox(height: 20),

              _Label(l.fieldNumberLabel),
              TextFormField(
                controller: _documentNumber,
                textCapitalization: TextCapitalization.characters,
                // Only a payment card is grouped: a passport number is not
                // written in fours, and spacing one would be wrong rather than
                // merely unfamiliar.
                keyboardType: _type == DocumentType.bankCard
                    ? TextInputType.number
                    : TextInputType.text,
                inputFormatters: _type == DocumentType.bankCard
                    ? const [CardNumberFormatter()]
                    : null,
                style: _type == DocumentType.bankCard
                    ? const TextStyle(
                        letterSpacing: 1.2,
                        fontFeatures: [FontFeature.tabularFigures()],
                      )
                    : null,
                decoration: InputDecoration(
                  hintText: l.fieldNumberHint,
                  prefixIcon: const Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 20),

              _Label(l.fieldExpiry),
              _DateField(
                value: _expiryDate,
                onChanged: (d) => setState(() => _expiryDate = d),
              ),
              const SizedBox(height: 20),

              _Label(l.fieldIssueDate),
              _DateField(
                value: _issueDate,
                onChanged: (d) => setState(() => _issueDate = d),
              ),
              const SizedBox(height: 20),

              _Label(l.fieldRemindMe),
              _LeadTimeField(
                expiry: _expiryDate,
                onPickDate: _pickReminderDate,
                selected: _reminderOffsets,
                onToggle: (days) => setState(() {
                  if (!_reminderOffsets.remove(days)) {
                    _reminderOffsets.add(days);
                  }
                  // Never leave a document with no reminder at all; that is a
                  // silent way to fail at the app's only job.
                  if (_reminderOffsets.isEmpty) _reminderOffsets.add(days);
                  _leadDaysIsAuto = false;
                }),
              ),
              const _DailyTailNote(),
              const SizedBox(height: 6),
              Text(
                _leadTimeExplanation(l),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
              ),

              if (_type.hasSixMonthTravelRule) ...[
                const SizedBox(height: 14),
                _InfoNote(icon: Icons.flight_takeoff, text: l.sixMonthRuleNote),
              ],

              if (_type.details.isNotEmpty) ...[
                const SizedBox(height: 28),
                ..._type.details.map(
                  (detail) => _DetailField(
                    detail: detail,
                    controller: _details[detail]!,
                    revealed: _revealed.contains(detail),
                    onToggleReveal: () => setState(() {
                      if (!_revealed.remove(detail)) _revealed.add(detail);
                    }),
                  ),
                ),
              ],

              const SizedBox(height: 28),
              _Label(l.fieldOptional),
              TextFormField(
                controller: _holder,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: l.fieldHolderHint,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),

              const SizedBox(height: 32),
              FilledButton(onPressed: _save, child: Text(l.editSave)),
            ],
          ),
        ),
      ),
    );
  }

  /// Whether anything on the form differs from what was there to begin with.
  ///
  /// Measured against the stored document, or against a blank form for a new
  /// one — so a document that arrived from the scanner and has never been
  /// saved counts as unsaved work, which it is.
  ///
  /// Pictures only count once they have finished loading. Until then the list
  /// is legitimately empty, and comparing it would call every freshly opened
  /// document unsaved.
  bool get _dirty {
    final existing = widget.existing;

    String text(TextEditingController c) => c.text.trim();
    bool differs(String a, String? b) => a != (b?.trim() ?? '');

    if (existing == null) {
      return _images.isNotEmpty ||
          text(_label).isNotEmpty ||
          text(_holder).isNotEmpty ||
          text(_documentNumber).isNotEmpty ||
          _expiryDate != null ||
          _issueDate != null ||
          _details.values.any((c) => text(c).isNotEmpty);
    }

    if (_type != existing.type) return true;
    if (differs(text(_label), existing.label)) return true;
    if (differs(text(_holder), existing.holder)) return true;
    if (differs(
      text(_documentNumber).replaceAll(' ', ''),
      existing.documentNumber?.replaceAll(' ', ''),
    )) {
      return true;
    }
    if (_issuingCountry != existing.issuingCountry) return true;
    if (_expiryDate != existing.expiryDate) return true;
    if (_issueDate != existing.issueDate) return true;
    if (!setEquals(_reminderOffsets, existing.reminderOffsetDays.toSet())) {
      return true;
    }

    for (final detail in DocumentDetail.values) {
      if (differs(text(_details[detail]!), existing.details[detail])) {
        return true;
      }
    }

    if (_imagesLoaded &&
        (_images.length != existing.imageCount || _imagesChanged)) {
      return true;
    }

    return false;
  }

  /// Whether leaving now is safe, asking if it is not.
  Future<bool> _mayLeave() async {
    if (!_dirty) return true;
    final l = L.of(context);

    final scheme = Theme.of(context).colorScheme;

    final choice = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.12),
                ),
                child: Icon(Icons.edit_note, size: 28, color: scheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                l.editUnsavedTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                l.editUnsavedBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 22),

              // Stacked, not squeezed into a row. Three actions along one
              // edge give each a third of the width and a truncated label,
              // and the one that destroys work ends up the same size and
              // weight as the one that does nothing.
              FilledButton(
                onPressed: () => Navigator.of(context).pop('save'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(l.editSave),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop('discard'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: scheme.error,
                  side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
                ),
                child: Text(l.editDiscard),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  foregroundColor: scheme.onSurfaceVariant,
                ),
                child: Text(l.actionCancel),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == 'save') {
      // _save closes the screen itself once it is satisfied. If it refuses —
      // no name, no expiry — staying put is the right outcome.
      await _save();
      return false;
    }
    return choice == 'discard';
  }

  /// The conventional set: when to start, then a tail as the date closes in.
  /// The reminder times a document starts with.
  ///
  /// The user's own default from Settings wins outright. Otherwise the
  /// conventional ladder, built from *this type's* renewal lead time — which
  /// is the better fallback precisely because it is not one list: a passport
  /// needs telling about months in advance, a gym membership does not.
  List<int> _defaultOffsets(int leadDays) {
    final preferred = ref.read(defaultRemindersProvider);
    if (preferred.isNotEmpty) {
      return [...preferred]..sort((a, b) => b.compareTo(a));
    }
    return <int>{
        leadDays,
        90,
        30,
        7,
        1,
      }.where((d) => d > 0 && d <= leadDays).toList()
      ..sort((a, b) => b.compareTo(a));
  }

  /// The earliest reminder, which is also when renewal should begin.
  int get _renewalLeadDays => _reminderOffsets.isEmpty
      ? 1
      : _reminderOffsets.reduce((a, b) => a > b ? a : b);

  String _leadTimeExplanation(L l) {
    if (_expiryDate == null) {
      return l.leadExplainNoDate(leadTimeLabel(l, _renewalLeadDays));
    }
    final start = _expiryDate!.subtract(Duration(days: _renewalLeadDays));
    if (start.isBefore(DateTime.now())) return l.leadExplainPassed;

    final locale = Localizations.localeOf(context).toLanguageTag();
    return l.leadExplainFirst(DateFormat.yMMMMd(locale).format(start));
  }

  Future<void> _save() async {
    final l = L.of(context);
    if (!_formKey.currentState!.validate()) return;

    if (_expiryDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.fieldExpiryRequired)));
      return;
    }

    final repo = ref.read(documentRepositoryProvider);
    final holder = _holder.text.trim();
    final number = _documentNumber.text.trim();
    final details = {
      for (final detail in _type.details)
        if (_details[detail]!.text.trim().isNotEmpty)
          detail: _details[detail]!.text.trim(),
    };

    if (_isEditing) {
      final updated = widget.existing!.copyWith(
        type: _type,
        label: _label.text.trim(),
        holder: holder.isEmpty ? null : holder,
        documentNumber: number.isEmpty ? null : number,
        issuingCountry: _issuingCountry,
        expiryDate: _expiryDate,
        issueDate: _issueDate,
        renewalLeadDays: _renewalLeadDays,
        reminderOffsets: _reminderOffsets.toList(),
        details: details,
      );
      if (_imagesLoaded) {
        // The editor holds the whole set, in the order shown, so it is written
        // back as it stands — that is what makes reordering and deleting work.
        final was = widget.existing!.imageCount;
        await repo.setImages(updated, _images);

        // Decrypted pictures are cached by document and page so that scrolling
        // the wallet does not decrypt the same photo on every frame. Nothing
        // in that key changes when the *contents* of a page are replaced, so
        // without this the home screen keeps showing the picture that was
        // retaken, reordered or deleted — the row updates, the image does not.
        for (
          var page = 0;
          page < (was > _images.length ? was : _images.length);
          page++
        ) {
          ref.invalidate(
            documentImageProvider(DocumentImageRef(updated.id, page)),
          );
        }
      } else {
        await repo.save(updated);
      }
    } else {
      // Permission first. iOS silently discards notifications scheduled while
      // the app is unauthorised, so creating the document before asking would
      // leave it with no reminders at all.
      await ref.read(notificationServiceProvider).requestPermission();

      await repo.create(
        type: _type,
        label: _label.text.trim(),
        expiryDate: _expiryDate!,
        renewalLeadDays: _renewalLeadDays,
        reminderOffsets: _reminderOffsets.toList(),
        holder: holder.isEmpty ? null : holder,
        documentNumber: number.isEmpty ? null : number,
        issuingCountry: _issuingCountry,
        issueDate: _issueDate,
        images: _images,
        details: details,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final l = L.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.editDeleteTitle),
        content: Text(l.editDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.actionDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(documentRepositoryProvider).delete(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }
}

/// The pictures of a document, in order.
///
/// Sized so the next tile always breaks the right edge: a strip whose contents
/// fit exactly gives no sign it scrolls, and people stopped at whatever fitted.
///
/// Hold one to drag it somewhere else in the row. Which side of a card came
/// out first is an accident of which way round it was lying, and the first
/// picture is the face shown in the wallet — so being able to say "that one"
/// matters more than it sounds.
class _CapturedPages extends StatelessWidget {
  const _CapturedPages({
    required this.images,
    required this.onAdd,
    required this.onTapImage,
    required this.onReorder,
  });

  final List<Uint8List> images;
  final VoidCallback onAdd;
  final ValueChanged<int> onTapImage;
  final void Function(int oldIndex, int newIndex) onReorder;

  /// Two whole tiles and a slice of the next.
  ///
  /// The slice is the point: a strip whose contents end flush with the edge
  /// gives no sign there is more, so people stopped at whatever fitted.
  static const _visibleTiles = 2.4;
  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - _gap) / _visibleTiles;
        final size = Size(width, width / kCardAspectRatio);

        return SizedBox(
          height: size.height,
          child: ReorderableListView.builder(
            scrollDirection: Axis.horizontal,
            onReorderItem: onReorder,
            itemCount: images.length,
            // Scrolls along with the pictures rather than sitting pinned to
            // the edge, so the row reads as one strip and reaching the add
            // tile is the same swipe as reaching the last photograph. A footer
            // is not reorderable, which is what keeps it at the end.
            footer: _AddPageTile(onTap: onAdd, size: size),
            // A long press starts the drag, which leaves a plain tap free for
            // the retake and delete choices.
            itemBuilder: (context, index) => Padding(
              key: ValueKey(images[index].hashCode ^ index),
              padding: const EdgeInsets.only(right: _gap),
              child: GestureDetector(
                onTap: () => onTapImage(index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    images[index],
                    width: size.width,
                    height: size.height,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AddPageTile extends StatelessWidget {
  const _AddPageTile({required this.onTap, required this.size});

  final VoidCallback onTap;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: scheme.onSurfaceVariant),
            const SizedBox(height: 6),
            Text(
              L.of(context).scanAddAnother,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// One type-specific field.
///
/// A security code is masked until asked for. It is the one value here worth
/// something to someone glancing over a shoulder — a card number on its own
/// cannot be used online without it — so it is hidden by default and never
/// appears on a card face.
class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.detail,
    required this.controller,
    required this.revealed,
    required this.onToggleReveal,
  });

  final DocumentDetail detail;
  final TextEditingController controller;
  final bool revealed;
  final VoidCallback onToggleReveal;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hidden = detail.isSensitive && !revealed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label(detail.label(l)),
          TextFormField(
            controller: controller,
            obscureText: hidden,
            autocorrect: !detail.isShort,
            enableSuggestions: !detail.isShort,
            keyboardType: detail.isShort ? TextInputType.visiblePassword : null,
            textCapitalization: detail.isShort
                ? TextCapitalization.characters
                : TextCapitalization.words,
            decoration: InputDecoration(
              suffixIcon: detail.isSensitive
                  ? TextButton(
                      onPressed: onToggleReveal,
                      child: Text(revealed ? l.detailHide : l.detailReveal),
                    )
                  : null,
            ),
          ),
          if (detail.isSensitive) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 13,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l.detailSensitiveNote,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// One choice in the picture sheet: a glyph, a name, and the whole width to
/// hit. Destructive actions take the error colour rather than a warning of
/// their own — the word and the red together are enough.
class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.colour,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? colour;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = colour ?? scheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Row(
          children: [
            Icon(icon, size: 22, color: tint),
            const SizedBox(width: 16),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: tint, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onChanged});

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(now.year + 5, now.month, now.day),
          firstDate: DateTime(now.year - 20),
          lastDate: DateTime(now.year + 50),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.event_outlined),
        ),
        child: Text(
          value == null
              ? l.fieldExpiryEmpty
              : DateFormat.yMMMMd(locale).format(value!),
          style: TextStyle(
            fontSize: 16,
            color: value == null ? scheme.onSurfaceVariant : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// When to be reminded — as many times as the user likes.
///
/// One reminder is rarely enough. Someone wants to hear about a passport nine
/// months out so they can start, and again a fortnight before they travel; a
/// single choice forced them to pick which of those mattered.
///
/// The earliest one selected is also when renewal should begin, so the status
/// on the list still follows it and nothing needs saying twice.
class _LeadTimeField extends StatelessWidget {
  const _LeadTimeField({
    required this.selected,
    required this.onToggle,
    required this.expiry,
    required this.onPickDate,
  });

  final Set<int> selected;
  final ValueChanged<int> onToggle;

  /// What the offsets are measured back from, so a chosen date can be shown
  /// as a date rather than as "173 days".
  final DateTime? expiry;

  final VoidCallback onPickDate;

  /// Presets rather than a free-form number: the exact day is not meaningful
  /// at this range, and a slider that lands on "173 days" makes the app feel
  /// fiddly.
  ///
  /// A week and a month are gone from the list because they are no longer a
  /// choice — every day of the final month is reminded on regardless, so
  /// offering them was offering something already guaranteed.
  static const _options = [60, 90, 120, 180, 270, 365];

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    // Anything chosen that is not one of the presets was picked as a date, and
    // is shown as one — the number of days back from expiry is the app's way
    // of storing it, not the user's way of having meant it.
    final custom = selected.where((d) => !_options.contains(d)).toList()
      ..sort((a, b) => b.compareTo(a));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final days in _options)
          FilterChip(
            label: Text(leadTimeLabel(l, days)),
            selected: selected.contains(days),
            onSelected: (_) => onToggle(days),
          ),
        for (final days in custom)
          FilterChip(
            label: Text(
              expiry == null
                  ? leadTimeLabel(l, days)
                  : l.leadOnDate(
                      DateFormat.yMMMd(locale)
                          .format(expiry!.subtract(Duration(days: days))),
                    ),
            ),
            selected: true,
            onSelected: (_) => onToggle(days),
          ),
        ActionChip(
          avatar: const Icon(Icons.event, size: 17),
          label: Text(l.leadCustom),
          onPressed: onPickDate,
        ),
      ],
    );
  }
}

/// The rule the user cannot switch off, said plainly.
///
/// A mandatory reminder that is never mentioned is indistinguishable from a
/// bug the first time it fires every morning.
class _DailyTailNote extends StatelessWidget {
  const _DailyTailNote();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.notifications_active_outlined,
            size: 17,
            color: scheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.leadDailyTitle,
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  l.leadDailyBody,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSecondaryContainer, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
