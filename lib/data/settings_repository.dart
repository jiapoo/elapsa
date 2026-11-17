import 'dart:convert';

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
  traditionalChinese,
  japanese,
  korean,
  german,
  french,
  portuguese,
  italian,
  spanish;

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
    AppLanguage.japanese => const Locale('ja'),
    AppLanguage.korean => const Locale('ko'),
    AppLanguage.german => const Locale('de'),
    AppLanguage.french => const Locale('fr'),
    AppLanguage.portuguese => const Locale('pt'),
    AppLanguage.italian => const Locale('it'),
    AppLanguage.spanish => const Locale('es'),
  };

  /// Shown in its own language, so someone who has the app in a language they
  /// cannot read can still find their way out.
  String get nativeName => switch (this) {
    AppLanguage.system => 'System',
    AppLanguage.english => 'English',
    AppLanguage.simplifiedChinese => '简体中文',
    AppLanguage.traditionalChinese => '繁體中文',
    AppLanguage.japanese => '日本語',
    AppLanguage.korean => '한국어',
    AppLanguage.german => 'Deutsch',
    AppLanguage.french => 'Français',
    AppLanguage.portuguese => 'Português (Brasil)',
    AppLanguage.italian => 'Italiano',
    AppLanguage.spanish => 'Español',
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

/// A kind of document the user invented.
///
/// Elapsa ships eleven types and will never ship the right eleven — a fishing
/// licence, a diving certificate, a parking permit, a season ticket. Rather
/// than guess wider, people name their own.
///
/// The name is the identity. That matters most when a document travels: a card
/// sent to a phone that has never heard of "Diving licence" arrives carrying
/// the name it was filed under, so it is never orphaned into "Other" at the
/// far end.
class CustomType {
  final String name;

  /// How far ahead this kind of thing needs renewing, in days.
  final int leadDays;

  /// Which of [icons] stands for it.
  final int icon;

  const CustomType({required this.name, this.leadDays = 60, this.icon = 0});

  /// A small, deliberately finite set. A picker of two thousand glyphs is a
  /// worse question than a picker of twelve.
  static const icons = <IconData>[
    Icons.folder_rounded,
    Icons.badge_rounded,
    Icons.description_rounded,
    Icons.card_membership_rounded,
    Icons.workspace_premium_rounded,
    Icons.verified_user_rounded,
    Icons.directions_car_rounded,
    Icons.house_rounded,
    Icons.fitness_center_rounded,
    Icons.pets_rounded,
    Icons.school_rounded,
    Icons.local_hospital_rounded,
    Icons.sailing_rounded,
    Icons.build_rounded,
    Icons.confirmation_number_rounded,
    Icons.key_rounded,
  ];

  IconData get glyph => icons[icon.clamp(0, icons.length - 1)];

  Map<String, dynamic> toJson() => {
    'name': name,
    'leadDays': leadDays,
    'icon': icon,
  };

  static CustomType? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final name = (raw['name'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;
    return CustomType(
      name: name,
      leadDays: (raw['leadDays'] as num?)?.toInt() ?? 60,
      icon: (raw['icon'] as num?)?.toInt() ?? 0,
    );
  }
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
  static const _typesKey = 'custom_types';
  static const _unlimitedKey = 'unlimited_unlocked';

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
      // By type until told otherwise. Urgency is already answered by the band
      // at the top of the wallet and by the colour on every card, so ordering
      // the rest by it repeats what is on screen. Type is how people think
      // they own documents — the passports together, the bank cards together —
      // and it is how they look for one.
      orElse: () => DocumentSort.type,
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

  List<CustomType> get customTypes {
    final stored = _prefs.getString(_typesKey);
    if (stored == null) return const [];
    try {
      return (jsonDecode(stored) as List)
          .map(CustomType.fromJson)
          .whereType<CustomType>()
          .toList();
    } catch (_) {
      // Written by a newer build, or damaged. Either way a broken list is
      // better dropped than allowed to take the settings screen down with it.
      return const [];
    }
  }

  /// The last answer StoreKit gave about the unlimited unlock.
  ///
  /// A cache, not the source of truth: it lets the app start in the right
  /// state with no network and no wait, and is corrected against StoreKit's
  /// own entitlements on every launch.
  bool get unlimitedUnlocked => _prefs.getBool(_unlimitedKey) ?? false;

  Future<void> setUnlimitedUnlocked(bool value) =>
      _prefs.setBool(_unlimitedKey, value);

  Future<void> setCustomTypes(List<CustomType> types) => _prefs.setString(
    _typesKey,
    jsonEncode([for (final type in types) type.toJson()]),
  );
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

/// The kinds of document the user has invented.
class CustomTypeController extends StateNotifier<List<CustomType>> {
  CustomTypeController(this._settings) : super(_settings.customTypes);

  final SettingsRepository _settings;

  Future<void> add(CustomType type) async {
    // By name, so adding one that already exists updates it rather than
    // leaving two entries that look identical and are not.
    final next = [
      for (final existing in state)
        if (existing.name != type.name) existing,
      type,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    state = next;
    await _settings.setCustomTypes(next);
  }

  Future<void> remove(String name) async {
    final next = [
      for (final type in state)
        if (type.name != name) type,
    ];
    state = next;
    await _settings.setCustomTypes(next);
  }

  /// Registers anything arriving from another phone that this one has never
  /// seen. Existing definitions win: the receiver's own choice of icon and
  /// lead time is theirs, and an import should not overwrite it.
  Future<void> adopt(Iterable<CustomType> types) async {
    final known = {for (final type in state) type.name};
    final missing = [
      for (final type in types)
        if (!known.contains(type.name)) type,
    ];
    if (missing.isEmpty) return;

    final next = [...state, ...missing]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    state = next;
    await _settings.setCustomTypes(next);
  }
}

final customTypesProvider =
    StateNotifierProvider<CustomTypeController, List<CustomType>>((ref) {
      return CustomTypeController(ref.watch(settingsRepositoryProvider));
    });

final defaultRemindersProvider =
    StateNotifierProvider<DefaultRemindersController, List<int>>((ref) {
      return DefaultRemindersController(ref.watch(settingsRepositoryProvider));
    });
