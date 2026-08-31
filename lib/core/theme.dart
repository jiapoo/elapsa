import 'package:flutter/material.dart';

import 'package:elapsa/domain/document.dart';

/// ISO/IEC 7810 ID-1 — the proportions of a bank card, national ID or driving
/// licence. Passports differ, but a wallet of mixed documents reads far better
/// when every card shares one silhouette.
const kCardAspectRatio = 1.586;

/// Elapsa's brand colour. Everything else is derived from it.
const kBrand = Color(0xFFDD1B3F);

/// Colour is the primary signal in this app — the list should be readable at a
/// glance without reading a word — so status colours are defined once here and
/// resolved against the active brightness rather than hard-coded per widget.
///
/// With a crimson brand, the severity scale runs *through* the brand rather
/// than beside it: expired is the brand red itself, then orange, then amber,
/// then green. A separate alarm red next to a red brand would read as two
/// different reds arguing, and neither would feel urgent.
class StatusPalette {
  final Color expired;
  final Color critical;
  final Color actionNeeded;
  final Color valid;

  const StatusPalette({
    required this.expired,
    required this.critical,
    required this.actionNeeded,
    required this.valid,
  });

  static const light = StatusPalette(
    expired: kBrand,
    critical: Color(0xFFC2410C),
    actionNeeded: Color(0xFF9A6700),
    valid: Color(0xFF2E7D46),
  );

  static const dark = StatusPalette(
    expired: Color(0xFFFF97AC),
    critical: Color(0xFFFFB77C),
    actionNeeded: Color(0xFFE8C766),
    valid: Color(0xFF7FD79B),
  );

  Color of(DocumentStatus status) => switch (status) {
        DocumentStatus.expired => expired,
        DocumentStatus.critical => critical,
        DocumentStatus.actionNeeded => actionNeeded,
        DocumentStatus.valid => valid,
      };

  static StatusPalette from(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

class ElapsaTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: kBrand,
      brightness: brightness,
      // Keep the brand exact rather than letting the tonal palette drift it —
      // this colour is the app's signature and appears beside its own icon.
      primary: brightness == Brightness.light ? kBrand : const Color(0xFFFF97AC),
    );

    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? scheme.primaryContainer : kBrand,
        foregroundColor: isDark ? scheme.onPrimaryContainer : Colors.white,
        elevation: 2,
        shape: const CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        selectedColor: scheme.primaryContainer,
        showCheckmark: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
