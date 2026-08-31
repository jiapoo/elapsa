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

/// How much of each document the wallet shows.
///
/// A wallet of photographs is the fastest thing to recognise — people know
/// their own cards by sight long before they read a label — but a photograph
/// of a document is also the thing you might not want on screen in a queue.
/// So the picture can be turned off without losing the list.
enum WalletDisplay {
  nameOnly,
  imageOnly,
  nameAndImage;

  bool get showsName => this != WalletDisplay.imageOnly;
  bool get showsImage => this != WalletDisplay.nameOnly;
}

/// Which theme the app paints itself in.
enum AppTheme {
  system,
  light,
  dark;

  ThemeMode get mode => switch (this) {
    AppTheme.system => ThemeMode.system,
    AppTheme.light => ThemeMode.light,
    AppTheme.dark => ThemeMode.dark,
  };
}

/// Persists the handful of choices the user makes about the app itself.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _languageKey = 'app_language';
  static const _sortKey = 'document_sort';
  static const _displayKey = 'wallet_display';
  static const _themeKey = 'app_theme';
  static const _remindersKey = 'default_reminders';

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

  WalletDisplay get display {
    final stored = _prefs.getString(_displayKey);
    return WalletDisplay.values.firstWhere(
      (d) => d.name == stored,
      orElse: () => WalletDisplay.nameAndImage,
    );
  }

  Future<void> setDisplay(WalletDisplay display) =>
      _prefs.setString(_displayKey, display.name);

  AppTheme get theme {
    final stored = _prefs.getString(_themeKey);
    return AppTheme.values.firstWhere(
      (t) => t.name == stored,
      orElse: () => AppTheme.system,
    );
  }

  Future<void> setTheme(AppTheme theme) =>
      _prefs.setString(_themeKey, theme.name);

  /// The reminder times a newly added document starts with.
  ///
  /// Empty means the user has expressed no preference, and each document falls
  /// back to the conventional set built from its own renewal lead time — which
  /// is a better default than any single list, because a passport and a gym
  /// membership do not deserve the same warning.
  List<int> get defaultReminders {
    final stored = _prefs.getStringList(_remindersKey);
    if (stored == null) return const [];
    return stored
        .map(int.tryParse)
        .whereType<int>()
        .where((d) => d > 0)
        .toList()
      ..sort((a, b) => b.compareTo(a));
  }

  Future<void> setDefaultReminders(List<int> days) =>
      _prefs.setStringList(_remindersKey, days.map((d) => '$d').toList());
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

final languageProvider = StateNotifierProvider<LanguageController, AppLanguage>(
  (ref) {
    return LanguageController(ref.watch(settingsRepositoryProvider));
  },
);

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

class DisplayController extends StateNotifier<WalletDisplay> {
  DisplayController(this._settings) : super(_settings.display);

  final SettingsRepository _settings;

  Future<void> select(WalletDisplay display) async {
    state = display;
    await _settings.setDisplay(display);
  }
}

final displayProvider = StateNotifierProvider<DisplayController, WalletDisplay>(
  (ref) {
    return DisplayController(ref.watch(settingsRepositoryProvider));
  },
);

class ThemeController extends StateNotifier<AppTheme> {
  ThemeController(this._settings) : super(_settings.theme);

  final SettingsRepository _settings;

  Future<void> select(AppTheme theme) async {
    state = theme;
    await _settings.setTheme(theme);
  }
}

final themeProvider = StateNotifierProvider<ThemeController, AppTheme>((ref) {
  return ThemeController(ref.watch(settingsRepositoryProvider));
});

class DefaultRemindersController extends StateNotifier<List<int>> {
  DefaultRemindersController(this._settings)
    : super(_settings.defaultReminders);

  final SettingsRepository _settings;

  Future<void> select(List<int> days) async {
    final sorted = [...days]..sort((a, b) => b.compareTo(a));
    state = sorted;
    await _settings.setDefaultReminders(sorted);
  }
}

final defaultRemindersProvider =
    StateNotifierProvider<DefaultRemindersController, List<int>>((ref) {
      return DefaultRemindersController(ref.watch(settingsRepositoryProvider));
    });

/// The text the recogniser last returned.
///
/// Held in memory and nowhere else. It is the single most useful thing to see
/// when a field comes back empty — it separates "the camera never read it"
/// from "the parser did not understand it" — but it is also the raw contents
/// of someone's card, so it is never written to disk.
final lastScanTextProvider = StateProvider<String>((ref) => '');
