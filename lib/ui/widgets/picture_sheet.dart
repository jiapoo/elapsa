
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';

import 'package:elapsa/l10n/app_localizations.dart';
import 'package:elapsa/core/theme.dart';

/// What can be done with one picture of a document.
enum PictureAction { crop, retake, saveToPhotos, saveToFiles, delete }

/// Offers [actions] for one picture, showing the picture itself.
///
/// A sheet rather than a dialog: three unlabelled thumbnails in a row look
/// much alike, and being asked "delete this one?" over a covered-up strip is a
/// good way to lose the wrong photograph. Shared by the read and edit screens
/// so a picture offers the same choices, in the same order, wherever it is
/// tapped.
Future<PictureAction?> showPictureSheet(
  BuildContext context, {
  required Uint8List image,
  required List<PictureAction> actions,
}) {
  // Tapping a picture does not take focus from a field above it, and the
  // keyboard would otherwise cover half the sheet.
  FocusManager.instance.primaryFocus?.unfocus();
  final scheme = Theme.of(context).colorScheme;

  return showModalBottomSheet<PictureAction>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: scheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _PictureSheet(image: image, actions: actions),
  );
}

class _PictureSheet extends StatelessWidget {
  const _PictureSheet({required this.image, required this.actions});

  final Uint8List image;
  final List<PictureAction> actions;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final exports = actions.any(
      (a) => a == PictureAction.saveToPhotos || a == PictureAction.saveToFiles,
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: kCardAspectRatio,
                child: Image.memory(image, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),

            // One panel, so the choices read as a set and the one that
            // destroys a picture sits inside the same frame as the ones that
            // do not — which is what makes its colour mean something.
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: 52,
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    _row(context, actions[i]),
                  ],
                ],
              ),
            ),

            if (exports) ...[
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
            const SizedBox(height: 10),

            // Its own button, at the same weight as the panel above it, so
            // the way out is never the least visible thing on the sheet.
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
    );
  }

  Widget _row(BuildContext context, PictureAction action) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (icon, label) = switch (action) {
      PictureAction.crop => (Icons.crop_rounded, l.actionCrop),
      PictureAction.retake => (Icons.photo_camera_rounded, l.actionRetake),
      PictureAction.saveToPhotos => (
        Icons.photo_library_outlined,
        l.actionSaveToPhotos,
      ),
      PictureAction.saveToFiles => (Icons.folder_outlined, l.actionSaveToFiles),
      PictureAction.delete => (Icons.delete_outline_rounded, l.actionDelete),
    };
    return SheetAction(
      icon: icon,
      label: label,
      colour: action == PictureAction.delete ? scheme.error : null,
      onTap: () => Navigator.of(context).pop(action),
    );
  }
}

/// One choice in a sheet: a glyph, a name, and the whole width to hit.
class SheetAction extends StatelessWidget {
  const SheetAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.colour,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: tint, fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
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

/// Puts a copy of [image] in the photo library, saying how it went.
///
/// Add-only access is all that is asked for: Elapsa has no reason to read
/// anyone's camera roll, only to drop one picture into it when told to.
Future<void> savePictureToPhotos(BuildContext context, Uint8List image) async {
  final l = L.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    if (!await Gal.hasPermission() && !await Gal.requestPermission()) {
      messenger.showSnackBar(SnackBar(content: Text(l.photoPhotosDenied)));
      return;
    }
    await Gal.putImageBytes(image, name: _pictureName());
    HapticFeedback.mediumImpact();
    messenger.showSnackBar(SnackBar(content: Text(l.photoSavedToPhotos)));
  } on GalException catch (error) {
    debugPrint('Elapsa: saving to Photos failed: ${error.type}');
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error.type == GalExceptionType.permissionDenied
              ? l.photoPhotosDenied
              : l.photoSaveFailed,
        ),
      ),
    );
  }
}

/// Hands a copy of [image] to the system's save-to-Files picker.
Future<void> savePictureToFiles(
  BuildContext context,
  Uint8List image, {
  required String baseName,
}) async {
  final l = L.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final saved = await FilePicker.platform.saveFile(
      fileName: '${_fileSafe(baseName)}.jpg',
      type: FileType.image,
      bytes: image,
    );
    // Null is the user closing the picker, which needs no comment.
    if (saved == null) return;
    messenger.showSnackBar(SnackBar(content: Text(l.photoSavedToFiles)));
  } catch (error) {
    debugPrint('Elapsa: saving to Files failed: $error');
    messenger.showSnackBar(SnackBar(content: Text(l.photoSaveFailed)));
  }
}

String _pictureName() => 'Elapsa-${DateTime.now().millisecondsSinceEpoch}';

String _fileSafe(String name) {
  final cleaned = name.replaceAll(RegExp(r'[/\\:*?"<>|\x00]'), '_').trim();
  return cleaned.isEmpty ? 'Elapsa' : cleaned;
}
