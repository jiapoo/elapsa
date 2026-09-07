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
import 'package:elapsa/services/card_cropper.dart';
import 'package:elapsa/services/nearby_transfer.dart';
import 'package:elapsa/services/vision_channel.dart';
import 'package:elapsa/ui/scan/crop_screen.dart';
import 'package:elapsa/ui/settings/nearby_screen.dart';
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

  /// True while the "keep your changes?" question is on screen.
  bool _asking = false;

  /// What the recogniser read for this document, kept so the question "why is
  /// this field empty" can be answered by whoever is holding the card.
  String? _scanText;

  /// The name of the user's own type this document is filed under, if any.
  String? _customType;

  /// True when this document simply has no end.
  bool _neverExpires = false;

  /// Fields the user added themselves, as a list so their order is theirs.
  final _extras =
      <({TextEditingController name, TextEditingController value})>[];

  /// What [_dirty] said at the last rebuild.
  ///
  /// Typing into a field changes a controller, not this widget, so nothing
  /// rebuilt and the guard on leaving kept whatever answer it had been given
  /// when the screen opened — which on an untouched document is "there is
  /// nothing to lose". Every edit made by typing therefore swiped away in
  /// silence. The controllers are watched now, and a rebuild happens on the
  /// one keystroke that changes the answer rather than on all of them.
  bool _wasDirty = false;

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
    _scanText = existing?.scanText;
    _customType = existing?.customType;

    for (final field
        in (existing?.extras ?? const <String, String>{}).entries) {
      _extras.add((
        name: TextEditingController(text: field.key),
        value: TextEditingController(text: field.value),
      ));
    }
    _neverExpires = existing?.neverExpires ?? false;
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

    for (final field in _watched) {
      field.addListener(_recheckDirty);
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

  /// Rebuilds only when the answer to "is there anything to lose" changes.
  void _recheckDirty() {
    final now = _dirty;
    if (now != _wasDirty && mounted) setState(() => _wasDirty = now);
  }

  @override
  void dispose() {
    for (final field in _watched) {
      field.removeListener(_recheckDirty);
    }
    for (final extra in _extras) {
      extra.name.dispose();
      extra.value.dispose();
    }
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

              // The three things you can do, in one panel. Grouped so they
              // read as a set of choices rather than a column of loose text,
              // and so the one that destroys a picture sits inside the same
              // frame as the ones that do not — which is what makes its colour
              // mean something.
              Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _SheetAction(
                      icon: Icons.crop_rounded,
                      label: l.actionCrop,
                      onTap: () => Navigator.of(context).pop('crop'),
                    ),
                    Divider(
                      height: 1,
                      indent: 52,
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    _SheetAction(
                      icon: Icons.photo_camera_rounded,
                      label: l.actionRetake,
                      onTap: () => Navigator.of(context).pop('retake'),
                    ),
                    Divider(
                      height: 1,
                      indent: 52,
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    _SheetAction(
                      icon: Icons.delete_outline_rounded,
                      label: l.actionDelete,
                      colour: scheme.error,
                      onTap: () => Navigator.of(context).pop('delete'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Its own button, at the same weight as the panel above it.
              // Cancel was a line of small text under three icon rows, which
              // made the way out the least visible thing on a sheet whose
              // other options are all irreversible.
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: scheme.surfaceContainerHighest.withValues(
                    alpha: 0.45,
                  ),
                  foregroundColor: scheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l.actionCancel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
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
    if (choice == 'delete') {
      await _persistImages();
      return;
    }

    // A retake replaces a picture, not the document. It still reads what it
    // can — a field left blank is worth filling from a better photograph —
    // but it will not overwrite an answer already on the form.
    await _scan(keepFilled: true);
  }

  /// Writes the pictures out, now.
  ///
  /// Cropping, retaking, deleting and reordering are finished actions on a
  /// picture, not pending edits to a form — so they are kept the moment they
  /// happen rather than waiting for a Save the user has no reason to think is
  /// still owed. A crop that vanishes because you left by the back arrow is
  /// indistinguishable from a crop that never worked.
  ///
  /// Only the pictures. The stored document's own fields go back untouched,
  /// so a name half-typed in the form above is still unsaved and still asked
  /// about on the way out.
  Future<void> _persistImages() async {
    final existing = widget.existing;
    if (existing == null || !_imagesLoaded) return;

    final was = existing.imageCount;
    await ref.read(documentRepositoryProvider).setImages(existing, _images);

    // Pictures are cached by document and page, and this replaces what sits
    // behind keys that have not changed.
    final pages = was > _images.length ? was : _images.length;
    for (var page = 0; page < pages; page++) {
      ref.invalidate(
        documentImageProvider(DocumentImageRef(existing.id, page)),
      );
    }
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
        MaterialPageRoute(
          builder: (_) => CropScreen(imagePath: temp!.path, startFull: true),
        ),
      );
      if (quad == null || !mounted) return;

      // Cut here rather than natively. The stored picture is already flat, so
      // there is no perspective to correct — and every complaint about this
      // crop was that the result was not the rectangle that had been drawn.
      // A measurement straight onto the pixels cannot drift.
      final cut = await const CardCropper().cropToQuad(temp.path, [
        quad.topLeft,
        quad.topRight,
        quad.bottomRight,
        quad.bottomLeft,
      ]);
      if (cut == null || !mounted) return;

      setState(() => _images[index] = cut);
      await _persistImages();
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

  /// Every text field whose contents decide whether leaving is safe.
  Iterable<TextEditingController> get _watched => [
    _label,
    _holder,
    _documentNumber,
    ..._details.values,
    for (final extra in _extras) ...[extra.name, extra.value],
  ];

  Future<void> _scan({bool keepFilled = false}) async {
    final session = await Navigator.of(
      context,
    ).push<ScanSession>(MaterialPageRoute(builder: (_) => const ScanScreen()));
    if (session != null) {
      _applySession(session, keepFilled: keepFilled);
      await _persistImages();
    }
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

    if (session.rawText.trim().isNotEmpty) _scanText = session.rawText;

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
      if (printed.neverExpires) _neverExpires = true;
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
      // Only while there is something to lose.
      //
      // Blocking the pop unconditionally also disabled the swipe back, which
      // is how people actually leave a screen on this platform — so a document
      // with nothing unsaved became one you could only escape by aiming at a
      // small arrow. Now the gesture works exactly as it always did, and only
      // an edited document interrupts it to ask.
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? l.editEditTitle : l.editAddTitle),
          titleTextStyle: Theme.of(context).textTheme.titleLarge,
          actions: [
            if (_isEditing)
              IconButton(
                // Not the system share glyph: this sends to a device in the
                // room, and offering the sheet that writes files would be
                // promising the wrong thing.
                icon: const Icon(Icons.wifi_tethering_rounded),
                tooltip: l.nearbyTitle,
                onPressed: _share,
              ),
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: l.actionDelete,
                onPressed: _confirmDelete,
              ),
          ],
        ),
        body: Stack(
          children: [
            Form(
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
                      onReorder: (from, to) {
                        setState(
                          () => _images.insert(to, _images.removeAt(from)),
                        );
                        _persistImages();
                      },
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: _scan,
                      icon: const Icon(Icons.document_scanner_rounded),
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
                      icon: Icons.verified_rounded,
                      text: _readAnything
                          ? l.editFromScanNote
                          : l.editScanNothingRead,
                    ),
                    const SizedBox(height: 24),
                  ],

                  _Label(l.fieldType),
                  // The user's own kinds sit in the same list as the eleven
                  // that ship. A separate picker for them would make an
                  // invented type feel like a lesser sort of type, which is
                  // the opposite of the point.
                  DropdownButtonFormField<String>(
                    initialValue: _customType == null
                        ? _type.name
                        : 'custom:$_customType',
                    isExpanded: true,
                    items: [
                      // Named kinds first, ours and theirs together, then
                      // "other" at the very end.
                      //
                      // "Other" is not a kind of document, it is the absence
                      // of one — so it belongs after everything that has a
                      // name, and in particular after the names the user
                      // invented, which exist precisely because "other" was
                      // not good enough.
                      for (final t in DocumentType.values)
                        if (t != DocumentType.other)
                          DropdownMenuItem(
                            value: t.name,
                            child: _TypeLine(icon: t.icon, label: t.label(l)),
                          ),
                      for (final custom in ref.watch(customTypesProvider))
                        DropdownMenuItem(
                          value: 'custom:${custom.name}',
                          child: _TypeLine(
                            icon: custom.glyph,
                            label: custom.name,
                          ),
                        ),
                      DropdownMenuItem(
                        value: DocumentType.other.name,
                        child: _TypeLine(
                          icon: DocumentType.other.icon,
                          label: DocumentType.other.label(l),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      final custom = value.startsWith('custom:')
                          ? ref
                                .read(customTypesProvider)
                                .where((t) => t.name == value.substring(7))
                                .firstOrNull
                          : null;

                      setState(() {
                        _customType = custom?.name;
                        // An invented type is filed under "other" underneath,
                        // so everything that reasons about a document — the
                        // travel rule, the detail fields — keeps working
                        // without having to know about it.
                        _type = custom != null
                            ? DocumentType.other
                            : DocumentType.values.firstWhere(
                                (t) => t.name == value,
                                orElse: () => DocumentType.other,
                              );

                        if (_leadDaysIsAuto) {
                          _reminderOffsets = {
                            ..._defaultOffsets(
                              custom?.leadDays ?? _type.defaultRenewalLeadDays,
                            ),
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

                  _Label(documentNumberLabel(l, _type)),
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
                      prefixIcon: const Icon(Icons.tag_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _Label(l.fieldExpiry),
                  if (!_neverExpires)
                    _DateField(
                      value: _expiryDate,
                      onChanged: (d) => setState(() => _expiryDate = d),
                    ),

                  // Offered beside the date rather than hidden in the type,
                  // because whether a document ends is a fact about that
                  // document and not about its kind: two memberships, one with
                  // a renewal date and one that runs until cancelled.
                  Padding(
                    padding: EdgeInsets.only(top: _neverExpires ? 0 : 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FilterChip(
                        avatar: Icon(
                          _neverExpires
                              ? Icons.all_inclusive_rounded
                              : Icons.event_busy_rounded,
                          size: 18,
                          color: _neverExpires
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                        label: Text(
                          _neverExpires ? l.fieldNeverExpires : l.fieldNoExpiry,
                        ),
                        selected: _neverExpires,
                        onSelected: (on) => setState(() {
                          _neverExpires = on;
                          // The date is kept, not cleared. Somebody who ticks
                          // this by accident should not have to find the card
                          // again to undo it.
                          if (on) _leadDaysIsAuto = true;
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _Label(l.fieldIssueDate),
                  _DateField(
                    value: _issueDate,
                    onChanged: (d) => setState(() => _issueDate = d),
                  ),
                  const SizedBox(height: 20),

                  // Nothing to remind about, so nothing to set. A reminder is
                  // a number of days before a date, and there is no date.
                  if (!_neverExpires) ...[
                    _Label(l.fieldRemindMe),
                    _LeadTimeField(
                      expiry: _expiryDate,
                      onPickDate: _pickReminderDate,
                      selected: _reminderOffsets,
                      onToggle: (days) => setState(() {
                        if (!_reminderOffsets.remove(days)) {
                          _reminderOffsets.add(days);
                        }
                        // Never leave a document with no reminder at all; that
                        // is a silent way to fail at the app's only job.
                        if (_reminderOffsets.isEmpty) {
                          _reminderOffsets.add(days);
                        }
                        _leadDaysIsAuto = false;
                      }),
                    ),
                    const _DailyTailNote(),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _leadTimeExplanation(l),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
                  ),

                  if (_type.hasSixMonthTravelRule) ...[
                    const SizedBox(height: 14),
                    _InfoNote(
                      icon: Icons.flight_takeoff_rounded,
                      text: l.sixMonthRuleNote,
                    ),
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
                      prefixIcon: const Icon(Icons.person_rounded),
                    ),
                  ),

                  const SizedBox(height: 28),
                  _Label(l.extrasTitle),
                  for (var i = 0; i < _extras.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 4,
                            child: TextFormField(
                              controller: _extras[i].name,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: l.extrasName,
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 5,
                            child: TextFormField(
                              controller: _extras[i].value,
                              decoration: InputDecoration(
                                hintText: l.extrasValue,
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(
                            iconSize: 19,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline_rounded),
                            color: scheme.onSurfaceVariant,
                            onPressed: () => setState(() {
                              final removed = _extras.removeAt(i);
                              removed.name.removeListener(_recheckDirty);
                              removed.value.removeListener(_recheckDirty);
                              removed.name.dispose();
                              removed.value.dispose();
                            }),
                          ),
                        ],
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        final field = (
                          name: TextEditingController(),
                          value: TextEditingController(),
                        );
                        field.name.addListener(_recheckDirty);
                        field.value.addListener(_recheckDirty);
                        _extras.add(field);
                      }),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(l.extrasAdd),
                    ),
                  ),

                  if (_scanText != null && _scanText!.trim().isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _ScanTextButton(text: _scanText!),
                  ],

                  const SizedBox(height: 32),
                  FilledButton(onPressed: _save, child: Text(l.editSave)),
                ],
              ),
            ),

            // The edge swipe, put back by hand.
            //
            // Refusing the pop is what protects unsaved work, but on this
            // platform refusing it does not *intercept* the back gesture — it
            // switches the gesture off. So swiping an edited document did
            // nothing at all and the alert never appeared. This strip catches
            // the same movement and asks the same question, and exists only
            // while the pop is being refused; the rest of the time the real
            // gesture is doing its own job.
            if (_dirty)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 26,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragEnd: (details) {
                    if ((details.primaryVelocity ?? 0) > 0) _leave();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Leaves the screen, asking first if anything would be lost.
  ///
  /// Guarded, because the back button and the edge swipe can both arrive
  /// before the first dialog has finished, and two stacked copies of the same
  /// question is its own kind of answer.
  Future<void> _leave() async {
    if (_asking) return;
    _asking = true;
    try {
      if (await _mayLeave() && mounted) Navigator.of(context).pop();
    } finally {
      _asking = false;
    }
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
          _neverExpires ||
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
    if (_neverExpires != existing.neverExpires) return true;
    if (!_neverExpires && _expiryDate != existing.expiryDate) return true;
    if (_issueDate != existing.issueDate) return true;
    if (!setEquals(_reminderOffsets, existing.reminderOffsetDays.toSet())) {
      return true;
    }

    for (final detail in DocumentDetail.values) {
      if (differs(text(_details[detail]!), existing.details[detail])) {
        return true;
      }
    }

    final named = {
      for (final extra in _extras)
        if (text(extra.name).isNotEmpty) text(extra.name): text(extra.value),
    };
    if (named.length != existing.extras.length) return true;
    for (final field in named.entries) {
      if (existing.extras[field.key] != field.value) return true;
    }

    // Pictures are not part of this question. They are written as they are
    // changed, so by the time anyone asks whether leaving is safe, there is
    // nothing about them left to lose.
    return false;
  }

  /// Hands this one document straight to another phone.
  ///
  /// The nearby transfer rather than a file: the whole point of sharing a
  /// single document is that somebody is standing there — lending a colleague
  /// an insurance card, giving a spouse a copy of a passport — and a file to
  /// carry it in would only be something for both of them to have to delete
  /// afterwards. Nothing is left on either phone this way, which is also why
  /// there is no passphrase to type.
  Future<void> _share() async {
    final existing = widget.existing;
    if (existing == null) return;
    final l = L.of(context);

    if (!NearbyTransfer.isAvailable) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.nearbyUnavailable)));
      return;
    }

    // What is on the screen is what gets sent. Handing over the stored copy
    // while the form holds unsaved corrections would give somebody the version
    // the user has just finished disagreeing with.
    if (_dirty) {
      await _save(close: false);
      if (!mounted || _dirty) return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NearbyScreen(selected: {existing.id}, sending: true),
      ),
    );
  }

  /// Whether leaving now is safe, asking if it is not.
  Future<bool> _mayLeave() async {
    if (!_dirty) return true;
    final l = L.of(context);

    final scheme = Theme.of(context).colorScheme;

    final choice = await showDialog<String>(
      context: context,
      builder: (context) => _Ask(
        icon: Icons.edit_note_rounded,
        tint: scheme.primary,
        title: l.editUnsavedTitle,
        body: l.editUnsavedBody,
        children: [
          // Stacked, not squeezed along one edge, where three answers each get
          // a third of the width and a truncated label — and the one that
          // destroys work ends up the same size and weight as the one that
          // does nothing.
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

  /// Writes the document.
  ///
  /// [close] is false when the caller has something to do with the saved
  /// record — sharing it, for one — and closing the screen underneath them
  /// would be the wrong answer to a button that says Share.
  Future<void> _save({bool close = true}) async {
    final l = L.of(context);
    if (!_formKey.currentState!.validate()) return;

    if (_expiryDate == null && !_neverExpires) {
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

    // A field with no name is not a field. One with a name and no value is
    // kept, because someone who has written "Member number" and not yet found
    // the card has said something worth keeping.
    final extras = {
      for (final extra in _extras)
        if (extra.name.text.trim().isNotEmpty)
          extra.name.text.trim(): extra.value.text.trim(),
    };

    if (_isEditing) {
      final updated = widget.existing!.copyWith(
        type: _type,
        label: _label.text.trim(),
        holder: holder.isEmpty ? null : holder,
        documentNumber: number.isEmpty ? null : number,
        issuingCountry: _issuingCountry,
        expiryDate: _expiryDate ?? DateTime.now(),
        neverExpires: _neverExpires,
        issueDate: _issueDate,
        renewalLeadDays: _renewalLeadDays,
        reminderOffsets: _reminderOffsets.toList(),
        details: details,
        scanText: _scanText,
        customType: _customType,
        clearCustomType: _customType == null,
        extras: extras,
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
        expiryDate: _expiryDate ?? DateTime.now(),
        neverExpires: _neverExpires,
        renewalLeadDays: _renewalLeadDays,
        reminderOffsets: _reminderOffsets.toList(),
        holder: holder.isEmpty ? null : holder,
        documentNumber: number.isEmpty ? null : number,
        issuingCountry: _issuingCountry,
        issueDate: _issueDate,
        images: _images,
        details: details,
        scanText: _scanText,
        customType: _customType,
        extras: extras,
      );
    }

    if (close && mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _Ask(
        icon: Icons.delete_outline_rounded,
        tint: scheme.error,
        title: l.editDeleteTitle,
        body: l.editDeleteBody,
        children: [
          // Filled in the error colour, not the brand one. It was the primary
          // button in Elapsa's own red, which is the shape and weight this app
          // uses for "yes, do the thing you came here for" — on a dialog
          // asking whether to destroy a document, that is the wrong promise.
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            child: Text(l.actionDelete),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              foregroundColor: scheme.onSurface,
            ),
            child: Text(
              l.actionCancel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
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
            Icon(Icons.add_a_photo_rounded, color: scheme.onSurfaceVariant),
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
                  Icons.lock_rounded,
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
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 21, color: tint),
            const SizedBox(width: 15),
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
          prefixIcon: Icon(Icons.event_rounded),
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
          avatar: const Icon(Icons.event_rounded, size: 17),
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
            Icons.notifications_active_rounded,
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

/// The shape every question in this screen is asked in.
///
/// A glyph, what is being asked, why it matters, then the answers stacked at
/// full width. One shell rather than three hand-built dialogs, so a
/// destructive answer looks the same wherever it appears — which is what makes
/// it recognisable at the speed people actually read a dialog.
class _Ask extends StatelessWidget {
  const _Ask({
    required this.icon,
    required this.tint,
    required this.title,
    required this.body,
    required this.children,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
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
                color: tint.withValues(alpha: 0.12),
              ),
              child: Icon(icon, size: 28, color: tint),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant, height: 1.45),
            ),
            const SizedBox(height: 22),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// One line in the type picker.
class _TypeLine extends StatelessWidget {
  const _TypeLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

/// What the camera read, kept out of the way until it is wanted.
///
/// It used to be one screen in Settings showing whatever was scanned last,
/// which answered the question only for whoever asked it within the minute.
/// Attached to its own document it answers "why is this field empty" for the
/// person actually holding that card, however long afterwards.
///
/// Deliberately not on the detail page: that page is for reading the document,
/// and a wall of recogniser output is about the app rather than about the
/// passport.
class _ScanTextButton extends StatelessWidget {
  const _ScanTextButton({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(Radii.control),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, scroll) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.editLastScan,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  l.settingsLastScanBody,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scroll,
                    child: SelectableText(
                      text,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        height: 1.55,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(Radii.control),
        ),
        child: Row(
          children: [
            Icon(
              Icons.document_scanner_rounded,
              size: 19,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                l.editLastScan,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
