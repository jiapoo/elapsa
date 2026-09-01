import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elapsa/core/labels.dart';
import 'package:elapsa/data/document_repository.dart';
import 'package:elapsa/data/settings_repository.dart';
import 'package:elapsa/l10n/app_localizations.dart';
import 'package:elapsa/ui/settings/custom_types_section.dart';
import 'package:elapsa/ui/settings/transfer_section.dart';

/// Everything the app can be told about itself, in one place.
///
/// Several of these also sit on the home screen, where they are one tap from
/// the thing they change. That duplication is deliberate: a control beside
/// what it affects is faster, but a settings page is where people look when
/// they do not already know a control exists.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.settingsTitle),
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // First, because it is the only thing on this page anyone arrives
          // with an errand for. Everything below it is a preference, and a
          // preference is something you go looking for; moving a library to a
          // new phone is something you came here to do.
          _SectionLabel(l.settingsTransfer),
          const TransferSection(),

          const SizedBox(height: 28),
          _SectionLabel(l.settingsTypes),
          const CustomTypesSection(),

          const SizedBox(height: 28),
          _SectionLabel(l.settingsWallet),
          _DisplayChoice(
            selected: ref.watch(displayProvider),
            onChanged: (value) =>
                ref.read(displayProvider.notifier).select(value),
          ),
          const SizedBox(height: 18),
          _Choice<DocumentSort>(
            title: l.sortTitle,
            values: DocumentSort.values,
            selected: ref.watch(sortProvider),
            label: (sort) => sort.label(l),
            onChanged: (value) => ref.read(sortProvider.notifier).select(value),
          ),

          const SizedBox(height: 28),
          _SectionLabel(l.settingsAppearance),
          _Choice<AppTheme>(
            title: l.settingsTheme,
            values: AppTheme.values,
            selected: ref.watch(themeProvider),
            label: (theme) => theme.label(l),
            onChanged: (value) =>
                ref.read(themeProvider.notifier).select(value),
          ),
          const SizedBox(height: 18),
          _Choice<AppLanguage>(
            title: l.settingsLanguage,
            values: AppLanguage.values,
            selected: ref.watch(languageProvider),
            // Each language is written in itself, so someone who has landed in
            // a script they cannot read can still find the way back out.
            label: (language) => language == AppLanguage.system
                ? l.settingsLanguageSystem
                : language.nativeName,
            onChanged: (value) =>
                ref.read(languageProvider.notifier).select(value),
          ),

          const SizedBox(height: 28),
          _SectionLabel(l.settingsRemindersTitle),
          const _DefaultReminders(),

          const SizedBox(height: 28),
          _SectionLabel(l.settingsAbout),
          const _Privacy(),
          const SizedBox(height: 16),
          Center(
            child: Text(
              l.settingsVersion('0.2.0'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The three wallet densities, each with the reason someone would want it.
///
/// A one-word label does not distinguish these — "picture only" sounds like a
/// preference until you read that it is also what stops a document being
/// legible to whoever is standing behind you.
class _DisplayChoice extends StatelessWidget {
  const _DisplayChoice({required this.selected, required this.onChanged});

  final WalletDisplay selected;
  final ValueChanged<WalletDisplay> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;

    return _Card(
      title: l.settingsWalletDisplay,
      child: Column(
        children: [
          for (final display in WalletDisplay.values)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onChanged(display),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      display == selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 20,
                      color: display == selected
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            display.label(l),
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            display.description(l),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                          ),
                        ],
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
}

/// The reminder times a new document starts with.
class _DefaultReminders extends ConsumerWidget {
  const _DefaultReminders();

  /// The same ladder the edit screen offers, so a default set here is a set
  /// the user can also recognise on the document itself.
  /// A week and a month are absent for the same reason they are absent from
  /// the document itself: every day of the final month is reminded on anyway.
  static const _options = [60, 90, 120, 180, 270, 365];

  static String _label(int days, L l) {
    if (days % 365 == 0) return l.leadYears(days ~/ 365);
    if (days % 30 == 0) return l.leadMonths(days ~/ 30);
    return l.leadWeeks((days / 7).round());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final chosen = ref.watch(defaultRemindersProvider);

    return _Card(
      title: l.settingsRemindersLead,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.settingsRemindersBody,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final days in _options)
                FilterChip(
                  label: Text(_label(days, l)),
                  selected: chosen.contains(days),
                  onSelected: (on) {
                    final next = [...chosen];
                    on ? next.add(days) : next.remove(days);
                    ref.read(defaultRemindersProvider.notifier).select(next);
                  },
                ),
            ],
          ),
          if (chosen.isEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 15,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.settingsRemindersAuto,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 6),
          _Action(
            icon: Icons.refresh_rounded,
            label: l.settingsResync,
            onTap: () async {
              await ref.read(documentRepositoryProvider).resync();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(l.settingsResyncDone)));
            },
          ),
        ],
      ),
    );
  }
}

class _Privacy extends StatelessWidget {
  const _Privacy();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.settingsPrivacyTitle,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l.settingsPrivacyBody,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// A one-of-several setting, shown as its options rather than as a menu.
///
/// Everything here is a handful of choices, and a page that lays them out is
/// read in one pass; a page of dropdowns has to be opened one at a time to
/// find out what it currently says.
class _Choice<T> extends StatelessWidget {
  const _Choice({
    required this.title,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final String title;
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _Card(
      title: title,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final value in values)
            ChoiceChip(
              label: Text(label(value)),
              selected: value == selected,
              showCheckmark: false,
              side: value == selected
                  ? BorderSide(color: scheme.primary, width: 1.4)
                  : null,
              onSelected: (_) => onChanged(value),
            ),
        ],
      ),
    );
  }
}

/// The container every setting sits in, so the page reads as a stack of
/// panels rather than an undifferentiated column of controls.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: primary),
            const SizedBox(width: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
