import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The languages Elapsa ships in.
///
/// Simplified and Traditional are separate entries rather than one "Chinese",
/// because they are not a character conversion of each other here: a mainland
/// user reads 驾驶证 and 身份证, a Taiwanese user reads 駕照 and 身分證.
enum AppLanguage {
  system,
  english,
  simplifiedChinese,
  traditionalChinese;

  /// Null means follow the device, which is what [system] does.
  Locale? get locale => switch (this) {
        AppLanguage.system => null,
        AppLanguage.english => const Locale('en'),
        AppLanguage.simplifiedChinese => const Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hans',
          ),
        AppLanguage.traditionalChinese => const Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hant',
          ),
      };

  /// Shown in its own language, so someone who has the app in a language they
  /// cannot read can still find their way out.
  String get nativeName => switch (this) {
        AppLanguage.system => 'System',
        AppLanguage.english => 'English',
        AppLanguage.simplifiedChinese => '简体中文',
        AppLanguage.traditionalChinese => '繁體中文',
      };
}

/// How the wallet is ordered.
///
/// Urgency still comes first whatever is chosen here — an expired passport
/// belongs at the top of the screen, not filed under P — so this orders
/// documents *within* the two sections rather than across them.
enum DocumentSort { expiry, added, name, type }

/// Persists the handful of choices the user makes about the app itself.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _languageKey = 'app_language';
  static const _sortKey = 'document_sort';

  AppLanguage get language {
    final stored = _prefs.getString(_languageKey);
    return AppLanguage.values.firstWhere(
      (l) => l.name == stored,
      orElse: () => AppLanguage.system,
    );
  }

  Future<void> setLanguage(AppLanguage language) =>
      _prefs.setString(_languageKey, language.name);

  DocumentSort get sort {
    final stored = _prefs.getString(_sortKey);
    return DocumentSort.values.firstWhere(
      (s) => s.name == stored,
      orElse: () => DocumentSort.expiry,
    );
  }

  Future<void> setSort(DocumentSort sort) =>
      _prefs.setString(_sortKey, sort.name);
}

/// Overridden in main() once SharedPreferences has loaded, so no screen has to
/// deal with settings being asynchronously absent.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('settingsRepositoryProvider must be overridden');
});

class LanguageController extends StateNotifier<AppLanguage> {
  LanguageController(this._settings) : super(_settings.language);

  final SettingsRepository _settings;

  Future<void> select(AppLanguage language) async {
    state = language;
    await _settings.setLanguage(language);
  }
}

final languageProvider =
    StateNotifierProvider<LanguageController, AppLanguage>((ref) {
  return LanguageController(ref.watch(settingsRepositoryProvider));
});

class SortController extends StateNotifier<DocumentSort> {
  SortController(this._settings) : super(_settings.sort);

  final SettingsRepository _settings;

  Future<void> select(DocumentSort sort) async {
    state = sort;
    await _settings.setSort(sort);
  }
}

final sortProvider = StateNotifierProvider<SortController, DocumentSort>((ref) {
  return SortController(ref.watch(settingsRepositoryProvider));
});
