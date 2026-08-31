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
  late int _renewalLeadDays;
  String? _issuingCountry;

  /// Pictures from this session. Empty on an edit means "leave what is stored
  /// alone" — only a fresh scan replaces them.
  final _images = <Uint8List>[];

  bool _fromScan = false;

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
    _documentNumber =
        TextEditingController(text: existing?.documentNumber ?? '');
    _expiryDate = existing?.expiryDate;
    _issuingCountry = existing?.issuingCountry;
    _renewalLeadDays = existing?.renewalLeadDays ?? _type.defaultRenewalLeadDays;
    _leadDaysIsAuto = existing == null ||
        existing.renewalLeadDays == existing.type.defaultRenewalLeadDays;

    final session = widget.session;
    if (session != null) {
      // Deferred, because filling the form needs the localisations that are
      // only available once there is a context.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _applySession(session));
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _holder.dispose();
    _documentNumber.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final session = await Navigator.of(context).push<ScanSession>(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (session != null) _applySession(session);
  }

  /// Folds a scan into the form.
  ///
  /// Everything stays editable afterwards. The check digits make a validated
  /// code near-certain to be right, but the user's own name for the document
  /// is theirs to choose, and a wrong guess should never be locked in.
  void _applySession(ScanSession session) {
    if (!mounted) return;
    final l = L.of(context);
    final mrz = session.mrz;

    setState(() {
      _fromScan = true;
      _readAnything = mrz != null || !session.printed.isEmpty;
      _images
        ..clear()
        ..addAll(session.images);

      // Printed fields first, so a validated MRZ can still override them.
      // Most documents have no MRZ at all — a Chinese 居民身份证 prints its
      // 有效期限 in plain sight and nothing else.
      final printed = session.printed;
      if (printed.type != null) {
        _type = printed.type!;
        if (_leadDaysIsAuto) {
          _renewalLeadDays = _type.defaultRenewalLeadDays;
        }
      }
      if (printed.expiryDate != null) _expiryDate = printed.expiryDate;
      if (printed.documentNumber != null &&
          _documentNumber.text.trim().isEmpty) {
        _documentNumber.text = printed.documentNumber!;
      }

      if (mrz == null) {
        if (_label.text.trim().isEmpty) _label.text = _type.label(l);
        return;
      }

      final scannedType = _typeFromDocumentCode(mrz.documentCode);
      if (scannedType != null) {
        _type = scannedType;
        if (_leadDaysIsAuto) {
          _renewalLeadDays = scannedType.defaultRenewalLeadDays;
        }
      }

      if (mrz.expiryDate != null) _expiryDate = mrz.expiryDate;
      if (mrz.documentNumber.isNotEmpty) {
        _documentNumber.text = mrz.documentNumber;
      }
      if (mrz.issuingState.isNotEmpty) _issuingCountry = mrz.issuingState;
      if (mrz.fullName.isNotEmpty && _holder.text.trim().isEmpty) {
        _holder.text = _titleCase(mrz.fullName);
      }
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

    return Scaffold(
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
              _CapturedPages(images: _images, onAdd: _scan),
              const SizedBox(height: 24),
            ] else if (_isEditing && widget.existing!.imageCount > 0) ...[
              _Label(l.fieldImages),
              _StoredPages(document: widget.existing!, onRescan: _scan),
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
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 28),
            ],

            if (_fromScan) ...[
              _InfoNote(
                icon: Icons.verified_outlined,
                text: _readAnything ? l.editFromScanNote : l.editScanNothingRead,
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
                    _renewalLeadDays = value.defaultRenewalLeadDays;
                  }
                });
              },
            ),
            const SizedBox(height: 20),

            _Label(l.fieldName),
            TextFormField(
              controller: _label,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  InputDecoration(hintText: l.fieldNameHint(_type.label(l))),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.fieldNameRequired : null,
            ),
            const SizedBox(height: 20),

            _Label(l.fieldExpiry),
            _DateField(
              value: _expiryDate,
              onChanged: (d) => setState(() => _expiryDate = d),
            ),
            const SizedBox(height: 20),

            _Label(l.fieldRemindMe),
            _LeadTimeField(
              days: _renewalLeadDays,
              onChanged: (days) => setState(() {
                _renewalLeadDays = days;
                _leadDaysIsAuto = false;
              }),
            ),
            const SizedBox(height: 6),
            Text(
              _leadTimeExplanation(l),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),

            if (_type.hasSixMonthTravelRule) ...[
              const SizedBox(height: 14),
              _InfoNote(
                icon: Icons.flight_takeoff,
                text: l.sixMonthRuleNote,
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _documentNumber,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: l.fieldNumberHint,
                prefixIcon: const Icon(Icons.tag),
              ),
            ),

            const SizedBox(height: 32),
            FilledButton(
              onPressed: _save,
              child: Text(_isEditing ? l.editSave : l.actionAdd),
            ),
          ],
        ),
      ),
    );
  }

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

    if (_isEditing) {
      final updated = widget.existing!.copyWith(
        type: _type,
        label: _label.text.trim(),
        holder: holder.isEmpty ? null : holder,
        documentNumber: number.isEmpty ? null : number,
        issuingCountry: _issuingCountry,
        expiryDate: _expiryDate,
        renewalLeadDays: _renewalLeadDays,
      );
      if (_images.isEmpty) {
        await repo.save(updated);
      } else {
        await repo.replaceImages(updated, _images);
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
        holder: holder.isEmpty ? null : holder,
        documentNumber: number.isEmpty ? null : number,
        issuingCountry: _issuingCountry,
        images: _images,
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

/// Pictures captured in this session, not yet saved.
class _CapturedPages extends StatelessWidget {
  const _CapturedPages({required this.images, required this.onAdd});

  final List<Uint8List> images;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == images.length) return _AddPageTile(onTap: onAdd);
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              images[index],
              width: 108 * kCardAspectRatio,
              height: 108,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}

/// Pictures already stored against a saved document.
class _StoredPages extends ConsumerWidget {
  const _StoredPages({required this.document, required this.onRescan});

  final TrackedDocument document;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: document.imageCount + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == document.imageCount) {
            return _AddPageTile(onTap: onRescan);
          }
          final bytes = ref
              .watch(documentImageProvider(DocumentImageRef(document.id, index)))
              .asData
              ?.value;
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: bytes == null
                ? Container(
                    width: 108 * kCardAspectRatio,
                    height: 108,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  )
                : Image.memory(
                    bytes,
                    width: 108 * kCardAspectRatio,
                    height: 108,
                    fit: BoxFit.cover,
                  ),
          );
        },
      ),
    );
  }
}

class _AddPageTile extends StatelessWidget {
  const _AddPageTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 108 * kCardAspectRatio,
        height: 108,
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
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
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

class _LeadTimeField extends StatelessWidget {
  const _LeadTimeField({required this.days, required this.onChanged});

  final int days;
  final ValueChanged<int> onChanged;

  /// Presets rather than a free-form number: the exact day is not meaningful,
  /// and a slider that lands on "173 days" makes the app feel fiddly.
  static const _options = [30, 60, 90, 120, 180, 270, 365];

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _options.map((d) {
        return ChoiceChip(
          label: Text(leadTimeLabel(l, d)),
          selected: d == days,
          onSelected: (_) => onChanged(d),
        );
      }).toList(),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                    height: 1.45,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
