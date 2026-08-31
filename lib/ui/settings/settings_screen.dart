import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elapsa/data/settings_repository.dart';
import 'package:elapsa/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final selected = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.settingsTitle),
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _SectionLabel(l.settingsLanguage),
          RadioGroup<AppLanguage>(
            groupValue: selected,
            onChanged: (value) {
              if (value != null) {
                ref.read(languageProvider.notifier).select(value);
              }
            },
            child: Column(
              children: AppLanguage.values
                  .map(
                    (language) => RadioListTile<AppLanguage>(
                      value: language,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(
                        // Each language is written in itself, so someone who
                        // has landed in a script they cannot read can still
                        // find the way back out.
                        language == AppLanguage.system
                            ? l.settingsLanguageSystem
                            : language.nativeName,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 28),
          _SectionLabel(l.settingsAbout),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_outline, size: 18, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.settingsPrivacyTitle,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l.settingsPrivacyBody,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: Text(
              l.settingsVersion('0.2.0'),
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
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
