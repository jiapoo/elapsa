import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elapsa/core/labels.dart';
import 'package:elapsa/core/theme.dart';
import 'package:elapsa/data/document_repository.dart';
import 'package:elapsa/data/settings_repository.dart';
import 'package:elapsa/l10n/app_localizations.dart';

/// Kinds of document the user names themselves.
class CustomTypesSection extends ConsumerWidget {
  const CustomTypesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final types = ref.watch(customTypesProvider);
    final documents = ref.watch(documentsProvider).asData?.value ?? const [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(Radii.panel),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.typesBody,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),

          if (types.isEmpty)
            Text(
              l.typesEmpty,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            )
          else
            for (final type in types)
              _TypeRow(
                type: type,
                // Counted so that removing one can say what it would strand.
                inUse: documents.where((d) => d.customType == type.name).length,
                onEdit: () => _compose(context, ref, existing: type),
                onRemove: () =>
                    ref.read(customTypesProvider.notifier).remove(type.name),
              ),

          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _compose(context, ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.add_rounded, size: 19, color: scheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    l.typesAdd,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _compose(
    BuildContext context,
    WidgetRef ref, {
    CustomType? existing,
  }) async {
    final made = await composeCustomType(context, existing: existing);
    if (made == null) return;
    await ref.read(customTypesProvider.notifier).add(made);
  }
}

/// Asks for a type's name, lead time and icon. Null if the user backs out.
///
/// Shared by Settings and the type dropdown on the document form, so a type
/// can be made at the moment it turns out to be missing rather than only after
/// a detour through Settings.
Future<CustomType?> composeCustomType(
  BuildContext context, {
  CustomType? existing,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<CustomType>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _TypeSheet(existing: existing),
    ),
  );
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.type,
    required this.inUse,
    required this.onEdit,
    required this.onRemove,
  });

  final CustomType type;
  final int inUse;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Icon(type.glyph, size: 20, color: scheme.onSurface),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    inUse > 0
                        ? l.typesInUse(inUse)
                        : leadTimeLabel(l, type.leadDays),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              iconSize: 19,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline_rounded),
              color: scheme.onSurfaceVariant,
              tooltip: l.typesRemove,
              // Removing a type does not touch the documents filed under it:
              // they keep the name they were given, so nothing is silently
              // refiled and adding the type back restores everything.
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

/// Naming one.
class _TypeSheet extends StatefulWidget {
  const _TypeSheet({this.existing});

  final CustomType? existing;

  @override
  State<_TypeSheet> createState() => _TypeSheetState();
}

class _TypeSheetState extends State<_TypeSheet> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late int _icon = widget.existing?.icon ?? 0;
  late int _leadDays = widget.existing?.leadDays ?? 60;

  static const _leadOptions = [30, 60, 90, 180, 365];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;

    // Scrolls, because with the keyboard up the sheet is taller than what is
    // left of the screen: it overflowed, and the Done button ended up under
    // the keyboard where nothing could reach it.
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.typesAdd, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l.typesName),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 18),
            Text(
              l.typesLead.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final days in _leadOptions)
                  ChoiceChip(
                    label: Text(leadTimeLabel(l, days)),
                    selected: _leadDays == days,
                    onSelected: (_) => setState(() => _leadDays = days),
                  ),
              ],
            ),

            const SizedBox(height: 18),
            // A small, finite set. A picker of two thousand glyphs is a worse
            // question than a picker of sixteen.
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < CustomType.icons.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => _icon = i),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: i == _icon
                            ? scheme.primary.withValues(alpha: 0.14)
                            : scheme.surfaceContainerHighest.withValues(
                                alpha: 0.6,
                              ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: i == _icon
                              ? scheme.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        CustomType.icons[i],
                        size: 21,
                        color: i == _icon
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 22),
            FilledButton(
              onPressed: _name.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(context).pop(
                      CustomType(
                        name: _name.text.trim(),
                        leadDays: _leadDays,
                        icon: _icon,
                      ),
                    ),
              child: Text(l.actionDone),
            ),
          ],
        ),
      ),
    );
  }
}
