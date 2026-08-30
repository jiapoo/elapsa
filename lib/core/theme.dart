import 'package:flutter/material.dart';

import 'package:elapsa/domain/document.dart';

/// Colour is the primary signal in this app — the list should be readable at a
/// glance without reading a word — so status colours are defined once here and
/// resolved against the active brightness rather than hard-coded per widget.
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
    expired: Color(0xFFB3261E),
    critical: Color(0xFFC2410C),
    actionNeeded: Color(0xFF9A6700),
    valid: Color(0xFF2E7D46),
  );

  static const dark = StatusPalette(
    expired: Color(0xFFF2B8B5),
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

String statusLabel(DocumentStatus status) => switch (status) {
      DocumentStatus.expired => 'Expired',
      DocumentStatus.critical => 'Expiring',
      DocumentStatus.actionNeeded => 'Renew now',
      DocumentStatus.valid => 'Valid',
    };

class ElapsaTheme {
  static const _seed = Color(0xFF2F6F62);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
    );
  }
}
