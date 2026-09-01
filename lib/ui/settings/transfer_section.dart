import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:elapsa/data/document_repository.dart';
import 'package:elapsa/data/settings_repository.dart';
import 'package:elapsa/l10n/app_localizations.dart';
import 'package:elapsa/services/document_archive.dart';
import 'package:elapsa/ui/settings/document_picker_screen.dart';
import 'package:elapsa/ui/settings/nearby_screen.dart';
import 'package:elapsa/ui/widgets/document_card_face.dart';

/// Moving a library to another phone.
///
/// Elapsa keeps everything on the device and nothing on a server, which is the
/// point of it — and which means a new phone has meant photographing every
/// document again, and a lost phone has meant losing the lot. One encrypted
/// file answers both, and the system share sheet carries it, so the app never
/// needs a transport of its own.
class TransferSection extends ConsumerStatefulWidget {
  const TransferSection({super.key});

  @override
  ConsumerState<TransferSection> createState() => _TransferSectionState();
}

class _TransferSectionState extends ConsumerState<TransferSection> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return Column(
      children: [
        _Panel(
          icon: Icons.ios_share_rounded,
          title: l.transferExport,
          body: l.transferExportBody,
          busy: _busy,
          onTap: _export,
        ),
        const SizedBox(height: 12),
        _Panel(
          icon: Icons.wifi_tethering_rounded,
          title: l.nearbyTitle,
          body: l.nearbyBody,
          busy: _busy,
          onTap: _nearby,
        ),
        const SizedBox(height: 12),
        _Panel(
          icon: Icons.download_rounded,
          title: l.transferImport,
          body: l.transferImportBody,
          busy: _busy,
          onTap: _import,
        ),
      ],
    );
  }

  Future<void> _export() async {
    final l = L.of(context);
    final repo = ref.read(documentRepositoryProvider);

    final all = await repo.getAll();
    if (!mounted) return;
    if (all.isEmpty) {
      _say(l.transferNothing);
      return;
    }

    // What to send, before anything is decrypted. Sending the whole library
    // is rarely what someone means by lending a colleague their insurance
    // card, and there is no undoing a document that has already gone.
    final choice = await Navigator.of(context).push<ExportChoice>(
      MaterialPageRoute(builder: (_) => DocumentPickerScreen(documents: all)),
    );
    if (choice == null || !mounted || choice.ids.isEmpty) return;

    final passphrase = choice.protect
        ? await _askPassphrase(confirm: true)
        : null;
    if (choice.protect && (passphrase == null || !mounted)) return;

    setState(() => _busy = true);
    try {
      final documents = await repo.exportDocuments(
        choice.ids,
        knownTypes: ref.read(customTypesProvider),
      );
      final bytes = await const DocumentArchive().pack(
        documents,
        passphrase: passphrase,
      );

      // A temporary file, not the documents directory: this one is *not*
      // encrypted with the device key, and it should not outlive the share.
      final stamp = DateTime.now().toIso8601String().split('T').first;
      final file = File(
        p.join((await getTemporaryDirectory()).path, 'elapsa-$stamp.elapsa'),
      );
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)]);

      if (mounted) _say(l.transferExported(documents.length));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Straight to another phone, with no file in between.
  Future<void> _nearby() async {
    // Which way round, before anything else. The two halves want different
    // screens — one picks documents, the other simply waits — and asking the
    // receiver to choose what to send first was asking a question that has no
    // answer on that side.
    final sending = await _askRole();
    if (sending == null || !mounted) return;

    if (!sending) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const NearbyScreen(selected: {}, sending: false),
        ),
      );
      return;
    }

    final all = await ref.read(documentRepositoryProvider).getAll();
    if (!mounted) return;
    if (all.isEmpty) {
      _say(L.of(context).transferNothing);
      return;
    }

    final choice = await Navigator.of(context).push<ExportChoice>(
      MaterialPageRoute(
        builder: (_) =>
            DocumentPickerScreen(documents: all, offerPassphrase: false),
      ),
    );
    if (choice == null || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NearbyScreen(selected: choice.ids, sending: true),
      ),
    );
    // Nothing to report back here: the nearby screen says what is happening
    // while it happens, which is the only moment that is useful.
  }

  Future<bool?> _askRole() {
    final l = L.of(context);

    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.nearbyRoleTitle,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _RoleChoice(
                icon: Icons.upload_rounded,
                title: l.nearbyRoleSend,
                body: l.nearbyRoleSendBody,
                onTap: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 8),
              _RoleChoice(
                icon: Icons.download_rounded,
                title: l.nearbyRoleReceive,
                body: l.nearbyRoleReceiveBody,
                onTap: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _import() async {
    final l = L.of(context);

    final picked = await FilePicker.platform.pickFiles(withData: true);
    final file = picked?.files.singleOrNull;
    if (file == null || !mounted) return;

    final bytes =
        file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null || !mounted) return;

    // Only asked for when the file actually has one, rather than making the
    // user guess whether the archive they were sent was protected.
    String? passphrase;
    if (const DocumentArchive().isProtected(bytes)) {
      passphrase = await _askPassphrase(confirm: false);
      if (passphrase == null || !mounted) return;
    }

    final replace = await _askReplace();
    if (replace == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final contents = await const DocumentArchive().unpack(
        bytes,
        passphrase: passphrase,
      );

      // The types first: a document filed under a name this phone has never
      // heard of should find that name waiting for it.
      await ref.read(customTypesProvider.notifier).adopt(contents.types);
      final count = await ref
          .read(documentRepositoryProvider)
          .importAll(contents.documents, replace: replace);

      // Pictures are cached by document and page, and an import replaces the
      // contents behind keys that have not changed.
      ref.invalidate(documentImageProvider);

      if (mounted) _say(l.transferImported(count));
    } on ArchiveException catch (error) {
      if (!mounted) return;
      _say(switch (error.reason) {
        ArchiveFailure.notAnArchive => l.transferFailedFile,
        ArchiveFailure.tooNew => l.transferFailedNew,
        ArchiveFailure.cannotOpen => l.transferFailedKey,
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Asks for the passphrase, twice when one is being chosen.
  ///
  /// Typed twice on the way out because a mistyped passphrase is not
  /// discovered until the archive will not open on the other phone, by which
  /// time the first one may well have been wiped.
  Future<String?> _askPassphrase({required bool confirm}) {
    return showDialog<String>(
      context: context,
      builder: (context) => _PassphraseDialog(confirm: confirm),
    );
  }

  Future<bool?> _askReplace() async {
    final l = L.of(context);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.transferMergeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Merge first and merge by default: it is the recoverable
            // mistake. An unwanted document can be deleted one at a time,
            // while a wrongly replaced library is simply gone.
            _ImportChoice(
              title: l.transferMerge,
              body: l.transferMergeBody,
              onTap: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: 6),
            _ImportChoice(
              title: l.transferReplace,
              body: l.transferReplaceBody,
              destructive: true,
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.actionCancel),
          ),
        ],
      ),
    );
  }

  void _say(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}

class _PassphraseDialog extends StatefulWidget {
  const _PassphraseDialog({required this.confirm});

  final bool confirm;

  @override
  State<_PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<_PassphraseDialog> {
  final _first = TextEditingController();
  final _second = TextEditingController();
  bool _shown = false;
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  void _submit() {
    final l = L.of(context);
    final value = _first.text;

    if (widget.confirm) {
      if (value.length < 8) {
        setState(() => _error = l.transferPassphraseShort);
        return;
      }
      if (value != _second.text) {
        setState(() => _error = l.transferPassphraseShort);
        return;
      }
    } else if (value.isEmpty) {
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return AlertDialog(
      title: Text(
        widget.confirm ? l.transferPassphraseNew : l.transferPassphrase,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.confirm
                ? l.transferPassphraseNewBody
                : l.transferPassphraseAsk,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _first,
            autofocus: true,
            obscureText: !_shown,
            decoration: InputDecoration(
              labelText: l.transferPassphrase,
              errorText: _error,
              suffixIcon: IconButton(
                icon: Icon(
                  _shown
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
                onPressed: () => setState(() => _shown = !_shown),
              ),
            ),
            onSubmitted: (_) => widget.confirm ? null : _submit(),
          ),
          if (widget.confirm) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _second,
              obscureText: !_shown,
              decoration: InputDecoration(labelText: l.transferPassphrase),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.actionCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l.actionContinue)),
      ],
    );
  }
}

class _ImportChoice extends StatelessWidget {
  const _ImportChoice({
    required this.title,
    required this.body,
    required this.onTap,
    this.destructive = false,
  });

  final String title;
  final String body;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = destructive ? scheme.error : scheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: tint, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              body,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.icon,
    required this.title,
    required this.body,
    required this.busy,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: busy ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: busy
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : Icon(icon, size: 20, color: scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
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
}

/// One half of the nearby question.
class _RoleChoice extends StatelessWidget {
  const _RoleChoice({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: scheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
