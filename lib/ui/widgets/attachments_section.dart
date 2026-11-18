import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:elapsa/core/theme.dart';
import 'package:elapsa/data/document_repository.dart';
import 'package:elapsa/domain/attachment.dart';
import 'package:elapsa/l10n/app_localizations.dart';
import 'package:elapsa/ui/widgets/picture_sheet.dart';

/// An attachment the user has just chosen, with the bytes when it is a file.
typedef PickedAttachment = ({Attachment attachment, Uint8List? bytes});

/// The files and links kept with a document.
///
/// Read-only when [onAdd] and [onRemove] are null — the detail screen — and
/// editable otherwise. Tapping an entry always opens it.
class AttachmentsSection extends StatelessWidget {
  const AttachmentsSection({
    super.key,
    required this.attachments,
    required this.onOpen,
    this.onAdd,
    this.onRemove,
  });

  final List<Attachment> attachments;
  final ValueChanged<Attachment> onOpen;
  final VoidCallback? onAdd;
  final ValueChanged<Attachment>? onRemove;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (attachments.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(Radii.panel),
            ),
            child: Column(
              children: [
                for (var i = 0; i < attachments.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 56,
                      color: scheme.outlineVariant,
                    ),
                  _AttachmentTile(
                    attachment: attachments[i],
                    onTap: () => onOpen(attachments[i]),
                    onRemove: onRemove == null
                        ? null
                        : () => onRemove!(attachments[i]),
                  ),
                ],
              ],
            ),
          ),
        if (onAdd != null)
          Padding(
            padding: EdgeInsets.only(top: attachments.isEmpty ? 0 : 6),
            child: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.attach_file_rounded, size: 18),
              label: Text(l.attachmentsAdd),
            ),
          ),
      ],
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.onTap,
    this.onRemove,
  });

  final Attachment attachment;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLink = attachment.kind == AttachmentKind.link;
    final subtitle = isLink
        ? Uri.tryParse(attachment.url ?? '')?.host ?? attachment.url ?? ''
        : [
            if (attachment.extension.isNotEmpty)
              attachment.extension.toUpperCase(),
            if (attachment.size != null) _formatSize(attachment.size!),
          ].join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.panel),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, onRemove == null ? 16 : 4, 12),
        child: Row(
          children: [
            Icon(_iconFor(attachment), size: 24, color: scheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            if (onRemove != null)
              IconButton(
                iconSize: 19,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline_rounded),
                color: scheme.onSurfaceVariant,
                tooltip: L.of(context).actionRemove,
                onPressed: onRemove,
              )
            else
              Icon(
                isLink ? Icons.open_in_new_rounded : Icons.chevron_right_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(Attachment a) {
    if (a.kind == AttachmentKind.link) return Icons.link_rounded;
    return switch (a.extension) {
      'pdf' => Icons.picture_as_pdf_rounded,
      'jpg' || 'jpeg' || 'png' || 'heic' || 'gif' || 'webp' =>
        Icons.image_outlined,
      'doc' || 'docx' || 'pages' || 'txt' || 'rtf' => Icons.description_outlined,
      'xls' || 'xlsx' || 'numbers' || 'csv' => Icons.table_chart_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Asks whether to attach files or a link, then gets them.
///
/// Several files can be chosen at once; a link is always one. Empty when the
/// user backs out at any point.
Future<List<PickedAttachment>> pickAttachment(BuildContext context) async {
  // A button does not take focus from the field being typed in, so without
  // this the keyboard stays up over the sheet and the system file picker —
  // and comes straight back when the link dialog closes, since a route hands
  // focus back to whatever had it.
  dismissKeyboard();
  final l = L.of(context);
  final scheme = Theme.of(context).colorScheme;

  final kind = await showModalBottomSheet<AttachmentKind>(
    context: context,
    showDragHandle: true,
    backgroundColor: scheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetAction(
                icon: Icons.insert_drive_file_outlined,
                label: l.attachmentsAddFile,
                subtitle: l.attachmentsAddFileHint,
                onTap: () => Navigator.of(context).pop(AttachmentKind.file),
              ),
              Divider(
                height: 1,
                indent: 52,
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
              SheetAction(
                icon: Icons.link_rounded,
                label: l.attachmentsAddLink,
                subtitle: l.attachmentsAddLinkHint,
                onTap: () => Navigator.of(context).pop(AttachmentKind.link),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (kind == null || !context.mounted) return const [];

  switch (kind) {
    case AttachmentKind.file:
      return _pickFiles(context);
    case AttachmentKind.link:
      final link = await _askForLink(context);
      return link == null ? const [] : [link];
  }
}

/// Takes focus away from any text field, so the keyboard goes down.
void dismissKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

Future<List<PickedAttachment>> _pickFiles(BuildContext context) async {
  final l = L.of(context);
  final messenger = ScaffoldMessenger.of(context);

  final FilePickerResult? result;
  try {
    result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
  } catch (error) {
    debugPrint('Elapsa: picking files failed: $error');
    return const [];
  }
  if (result == null) return const [];

  final picked = <PickedAttachment>[];
  var tooLarge = 0;
  for (final file in result.files) {
    // One oversized file is left out rather than refusing the whole choice:
    // the other four were fine, and choosing them again is tedious.
    if (file.size > DocumentRepository.maxAttachmentBytes) {
      tooLarge++;
      continue;
    }
    var bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null) continue;
    picked.add((
      attachment: DocumentRepository.newFile(
        name: file.name,
        size: bytes.length,
      ),
      bytes: bytes,
    ));
  }

  if (tooLarge > 0) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.files.length == 1
              ? l.attachmentsTooLarge
              : l.attachmentsSkippedTooLarge(tooLarge),
        ),
      ),
    );
  }
  return picked;
}

Future<PickedAttachment?> _askForLink(BuildContext context) async {
  final url = await showDialog<({Uri url, String name})>(
    context: context,
    builder: (_) => const _LinkDialog(),
  );
  if (url == null) return null;
  return (
    attachment: DocumentRepository.newLink(name: url.name, url: url.url),
    bytes: null,
  );
}

class _LinkDialog extends StatefulWidget {
  const _LinkDialog();

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  final _url = TextEditingController();
  final _name = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final uri = Attachment.normaliseUrl(_url.text);
    if (uri == null) {
      setState(() => _error = L.of(context).attachmentsLinkInvalid);
      return;
    }
    Navigator.of(context).pop((url: uri, name: _name.text));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return AlertDialog(
      title: Text(l.attachmentsLinkTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _url,
            autofocus: true,
            keyboardType: TextInputType.url,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: l.attachmentsLinkUrl,
              errorText: _error,
              prefixIcon: const Icon(Icons.link_rounded),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(hintText: l.attachmentsLinkName),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.actionCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l.actionAddShort)),
      ],
    );
  }
}

/// What a tap on an attachment does.
///
/// A link goes straight to the browser, there being nothing else to do with
/// one. A file offers a choice: look at it here, or hand it to another app
/// through the system share sheet.
Future<void> tapAttachment(
  BuildContext context,
  WidgetRef ref, {
  required String? documentId,
  required Attachment attachment,
  Uint8List? pendingBytes,
}) async {
  if (attachment.kind == AttachmentKind.file) {
    dismissKeyboard();
    final share = await _askOpenOrShare(context, attachment);
    if (share == null || !context.mounted) return;
    if (share) {
      return _shareAttachment(
        context,
        ref,
        documentId: documentId,
        attachment: attachment,
        pendingBytes: pendingBytes,
      );
    }
  }
  return openAttachment(
    context,
    ref,
    documentId: documentId,
    attachment: attachment,
    pendingBytes: pendingBytes,
  );
}

/// True to share, false to open, null to do neither.
Future<bool?> _askOpenOrShare(BuildContext context, Attachment attachment) {
  final l = L.of(context);
  final scheme = Theme.of(context).colorScheme;

  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    backgroundColor: scheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
              child: Text(
                attachment.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SheetAction(
                    icon: Icons.visibility_outlined,
                    label: l.actionOpen,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                  Divider(
                    height: 1,
                    indent: 52,
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  SheetAction(
                    icon: Icons.ios_share_rounded,
                    label: l.actionShare,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(width: 4),
                Icon(
                  Icons.lock_open_rounded,
                  size: 13,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l.photoExportNote,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// A decrypted copy of a file for another app to read, or null if it is gone.
///
/// [pendingBytes] is for a file added to a document that has not been saved
/// yet, so has nothing on disk to decrypt.
Future<File?> _plainCopy(
  WidgetRef ref, {
  required String? documentId,
  required Attachment attachment,
  Uint8List? pendingBytes,
}) async {
  final store = ref.read(attachmentStoreProvider);
  if (pendingBytes != null) {
    await store.clearOpened();
    final dir = Directory(
      p.join((await getTemporaryDirectory()).path, 'elapsa-open'),
    );
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, attachment.name.replaceAll('/', '_')));
    return file.writeAsBytes(pendingBytes, flush: true);
  }
  if (documentId == null) return null;
  return store.decryptForViewing(documentId, attachment.id, attachment.name);
}

Future<void> _shareAttachment(
  BuildContext context,
  WidgetRef ref, {
  required String? documentId,
  required Attachment attachment,
  Uint8List? pendingBytes,
}) async {
  final l = L.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final origin = shareOriginOf(context);
  final store = ref.read(attachmentStoreProvider);

  try {
    final file = await _plainCopy(
      ref,
      documentId: documentId,
      attachment: attachment,
      pendingBytes: pendingBytes,
    );
    if (file == null) {
      messenger.showSnackBar(SnackBar(content: Text(l.shareFailed)));
      return;
    }
    await Share.shareXFiles([XFile(file.path)], sharePositionOrigin: origin);
  } catch (error) {
    debugPrint('Elapsa: sharing an attachment failed: $error');
    messenger.showSnackBar(SnackBar(content: Text(l.shareFailed)));
  } finally {
    await store.clearOpened();
  }
}

/// Opens an attachment: a link in the browser, a file in the system viewer.
///
/// [pendingBytes] is for a file added to a document that has not been saved
/// yet, so has nothing on disk to decrypt.
Future<void> openAttachment(
  BuildContext context,
  WidgetRef ref, {
  required String? documentId,
  required Attachment attachment,
  Uint8List? pendingBytes,
}) async {
  final l = L.of(context);
  final messenger = ScaffoldMessenger.of(context);
  void failed() =>
      messenger.showSnackBar(SnackBar(content: Text(l.attachmentsCannotOpen)));

  try {
    if (attachment.kind == AttachmentKind.link) {
      final uri = Attachment.normaliseUrl(attachment.url ?? '');
      if (uri == null ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        failed();
      }
      return;
    }

    final file = await _plainCopy(
      ref,
      documentId: documentId,
      attachment: attachment,
      pendingBytes: pendingBytes,
    );
    if (file == null) return failed();

    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) failed();
  } catch (error) {
    debugPrint('Elapsa: opening an attachment failed: $error');
    failed();
  }
}

/// Asks before a file is deleted for good. Links go without asking: one can
/// be typed in again, a file's only copy cannot.
Future<bool> confirmRemoveAttachment(
  BuildContext context,
  Attachment attachment,
) async {
  if (attachment.kind == AttachmentKind.link) return true;
  final l = L.of(context);
  final scheme = Theme.of(context).colorScheme;
  final yes = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.attachmentsRemoveTitle),
      content: Text(l.attachmentsRemoveBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: Text(l.actionRemove),
        ),
      ],
    ),
  );
  return yes == true;
}
