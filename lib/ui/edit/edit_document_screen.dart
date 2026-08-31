import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:elapsa/core/lead_time.dart';
import 'package:elapsa/data/document_repository.dart';
import 'package:elapsa/domain/document.dart';
import 'package:elapsa/domain/document_type.dart';
import 'package:elapsa/ui/scan/scan_screen.dart';

final _dateFormat = DateFormat('d MMMM yyyy');

class EditDocumentScreen extends ConsumerStatefulWidget {
  const EditDocumentScreen({super.key, this.existing});

  final TrackedDocument? existing;

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

  /// Photo from a scan, still in a temp directory. It is encrypted into the
  /// app's own storage on save — not before, because the document needs an id
  /// first and an abandoned form should leave nothing behind.
  Uint8List? _cardImage;

  /// Set when the fields came from a scan rather than being typed, so the UI
  /// can say so — people are reasonably suspicious of a form that filled
  /// itself in with their passport number.
  bool _fromScan = false;

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
    _documentNumber = TextEditingController(text: existing?.documentNumber ?? '');
    _expiryDate = existing?.expiryDate;
    _issuingCountry = existing?.issuingCountry;
    _renewalLeadDays = existing?.renewalLeadDays ?? _type.defaultRenewalLeadDays;
    _leadDaysIsAuto = existing == null ||
        existing.renewalLeadDays == existing.type.defaultRenewalLeadDays;
  }

  @override
  void dispose() {
    _label.dispose();
    _holder.dispose();
    _documentNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit document' : 'Add document'),
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            if (!_isEditing) ...[
              OutlinedButton.icon(
                onPressed: _scan,
                icon: const Icon(Icons.document_scanner_outlined),
                label: const Text('Scan document'),
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
                  'Reads the code on a passport, ID card or visa',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 28),
            ],

            if (_fromScan) ...[
              _InfoNote(
                icon: Icons.verified_outlined,
                text: 'Filled in from the document code. Every field is still '
                    'yours to change.',
              ),
              const SizedBox(height: 24),
            ],

            _Label('Type'),
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
                          Text(t.label),
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

            _Label('Name'),
            TextFormField(
              controller: _label,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: 'My ${_type.label.toLowerCase()}'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Give it a name' : null,
            ),
            const SizedBox(height: 20),

            _Label('Expiry date'),
            _DateField(
              value: _expiryDate,
              onChanged: (d) => setState(() => _expiryDate = d),
            ),
            const SizedBox(height: 20),

            _Label('Start reminding me'),
            _LeadTimeField(
              days: _renewalLeadDays,
              onChanged: (days) => setState(() {
                _renewalLeadDays = days;
                _leadDaysIsAuto = false;
              }),
            ),
            const SizedBox(height: 6),
            Text(
              _leadTimeExplanation(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),

            if (_type.hasSixMonthTravelRule) ...[
              const SizedBox(height: 14),
              _InfoNote(
                icon: Icons.flight_takeoff,
                text: 'Many countries require six months of validity beyond '
                    'your entry date, so this document stops being usable for '
                    'travel about six months before it expires.',
              ),
            ],

            const SizedBox(height: 28),
            _Label('Optional'),
            TextFormField(
              controller: _holder,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Who it belongs to',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _documentNumber,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Document number',
                prefixIcon: Icon(Icons.tag),
              ),
            ),

            const SizedBox(height: 32),
            FilledButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Save changes' : 'Add document'),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the scanner and folds any result into the form.
  ///
  /// Everything stays editable afterwards. The check digits make a validated
  /// MRZ near-certain to be right, but the user's own name for the document is
  /// theirs to choose, and a wrong guess should never be locked in.
  Future<void> _scan() async {
    final capture = await Navigator.of(context).push<ScanCapture>(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (capture == null || !mounted) return;

    final result = capture.mrz;

    setState(() {
      _fromScan = true;
      _cardImage = capture.cardImage;

      final scannedType = _typeFromDocumentCode(result.documentCode);
      if (scannedType != null) {
        _type = scannedType;
        if (_leadDaysIsAuto) {
          _renewalLeadDays = scannedType.defaultRenewalLeadDays;
        }
      }

      if (result.expiryDate != null) _expiryDate = result.expiryDate;
      if (result.documentNumber.isNotEmpty) {
        _documentNumber.text = result.documentNumber;
      }
      if (result.issuingState.isNotEmpty) {
        _issuingCountry = result.issuingState;
      }
      if (result.fullName.isNotEmpty && _holder.text.trim().isEmpty) {
        _holder.text = _titleCase(result.fullName);
      }
      if (_label.text.trim().isEmpty) {
        _label.text = _type.label;
      }
    });

    if (result.wasRepaired && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scanned — the code was a little blurry, so please '
              'check the details.'),
        ),
      );
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

  String _leadTimeExplanation() {
    if (_expiryDate == null) {
      return 'Elapsa will remind you ${leadTimeLabel(_renewalLeadDays)} before '
          'it expires, then again as the date approaches.';
    }
    final start = _expiryDate!.subtract(Duration(days: _renewalLeadDays));
    final when = _dateFormat.format(start);
    return start.isBefore(DateTime.now())
        ? 'That window has already passed — you should start now.'
        : 'First reminder on $when, then again as the date approaches.';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick an expiry date')),
      );
      return;
    }

    final repo = ref.read(documentRepositoryProvider);
    final holder = _holder.text.trim();
    final number = _documentNumber.text.trim();

    if (_isEditing) {
      await repo.save(
        widget.existing!.copyWith(
          type: _type,
          label: _label.text.trim(),
          holder: holder.isEmpty ? null : holder,
          documentNumber: number.isEmpty ? null : number,
          issuingCountry: _issuingCountry,
          expiryDate: _expiryDate,
          renewalLeadDays: _renewalLeadDays,
        ),
      );
    } else {
      // Ask for permission *before* the first save. iOS silently discards any
      // notification scheduled while the app is unauthorised, so creating the
      // document first would leave it with no reminders at all. The prompt is
      // still shown in context — the user has just committed to adding
      // something worth being reminded about, which is what makes them say yes.
      await ref.read(notificationServiceProvider).requestPermission();

      await repo.create(
        type: _type,
        label: _label.text.trim(),
        expiryDate: _expiryDate!,
        renewalLeadDays: _renewalLeadDays,
        holder: holder.isEmpty ? null : holder,
        documentNumber: number.isEmpty ? null : number,
        issuingCountry: _issuingCountry,
        cardImage: _cardImage,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this document?'),
        content: const Text('Its reminders will be cancelled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(documentRepositoryProvider).delete(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
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
    final scheme = Theme.of(context).colorScheme;

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
          value == null ? 'Select a date' : _dateFormat.format(value!),
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _options.map((d) {
        final selected = d == days;
        return ChoiceChip(
          label: Text(leadTimeLabel(d)),
          selected: selected,
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
