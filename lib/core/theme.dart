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

/// The shapes this app is drawn with.
///
/// Named once rather than typed at each call site, because a radius that
/// varies by two points between a card and the sheet it opens is the kind of
/// thing nobody can name and everybody feels.
class Radii {
  static const card = 20.0;
  static const panel = 18.0;
  static const control = 14.0;
  static const chip = 11.0;
  static const sheet = 28.0;
}

class ElapsaTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme =
        ColorScheme.fromSeed(
          seedColor: kBrand,
          brightness: brightness,
          // Keep the brand exact rather than letting the tonal palette drift
          // it — this colour is the app's signature and appears beside its own
          // icon.
          primary: isDark ? const Color(0xFFFF97AC) : kBrand,
        ).copyWith(
          // Neutrals with a breath of the brand in them. A pure grey beside a
          // crimson reads as two unrelated decisions; the same grey warmed a
          // few points towards it reads as one palette, without anyone being
          // able to say why.
          surface: isDark ? const Color(0xFF141012) : const Color(0xFFFFFBFC),
          surfaceContainerLowest: isDark
              ? const Color(0xFF0E0B0C)
              : Colors.white,
          surfaceContainerLow: isDark
              ? const Color(0xFF1A1517)
              : const Color(0xFFFAF4F6),
          surfaceContainer: isDark
              ? const Color(0xFF1F191B)
              : const Color(0xFFF5EEF0),
          surfaceContainerHigh: isDark
              ? const Color(0xFF262022)
              : const Color(0xFFF0E8EA),
          surfaceContainerHighest: isDark
              ? const Color(0xFF2E2729)
              : const Color(0xFFEAE1E3),
          outlineVariant: isDark
              ? const Color(0xFF3A3235)
              : const Color(0xFFE2D8DB),
        );

    final text = _typography(scheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineSmall,
        iconTheme: IconThemeData(color: scheme.onSurface, size: 23),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        margin: EdgeInsets.zero,
      ),

      // Fields with no boxes round them. An outline on every input turns a
      // form into a grid of empty rectangles; a quiet fill says "type here"
      // just as clearly and lets the values be the thing you see.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh.withValues(
          alpha: isDark ? 0.6 : 0.75,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.control),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.control),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.control),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.control),
          borderSide: BorderSide(color: scheme.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.control),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        hintStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.control),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.control),
          ),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.control),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? scheme.primaryContainer : kBrand,
        foregroundColor: isDark ? scheme.onPrimaryContainer : Colors.white,
        elevation: 3,
        focusElevation: 3,
        hoverElevation: 3,
        highlightElevation: 3,
        shape: const CircleBorder(),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh.withValues(alpha: 0.7),
        selectedColor: isDark
            ? scheme.primary.withValues(alpha: 0.22)
            : scheme.primary.withValues(alpha: 0.11),
        showCheckmark: false,
        side: BorderSide.none,
        labelStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.chip),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sheet),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radii.sheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? scheme.surfaceContainerHighest
            : scheme.onSurface,
        contentTextStyle: TextStyle(
          color: isDark ? scheme.onSurface : scheme.surface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.control),
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.control),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: Colors.transparent,
      ),
    );
  }

  /// One scale, set once.
  ///
  /// Tight tracking on the large sizes and a touch of air in the small ones:
  /// headings are read as shapes and want to be compact, while a countdown or
  /// a status word is read letter by letter and wants room. The figures in
  /// this app are dates, days and card numbers, so they are set to line up in
  /// columns wherever they appear.
  static TextTheme _typography(ColorScheme scheme) {
    final base = ThemeData(brightness: scheme.brightness).textTheme;

    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 27,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: scheme.onSurface,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16.5,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.05,
      ),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 15.5, height: 1.4),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14.5, height: 1.45),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 13,
        height: 1.45,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}
