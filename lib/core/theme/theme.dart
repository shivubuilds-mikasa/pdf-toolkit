import 'dart:ui';

import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData darkTheme = _buildTheme(Brightness.dark);
  static final ThemeData lightTheme = _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? const Color(0xFF9B8CFF) : const Color(0xFF6254D9);
    final secondary =
        isDark ? const Color(0xFF79DCC8) : const Color(0xFF168C81);
    final foreground =
        isDark ? const Color(0xFFF6F4FF) : const Color(0xFF1D1A32);
    final muted = isDark ? const Color(0xFFB9B6CC) : const Color(0xFF68657A);
    final base = isDark ? const Color(0xFF15172B) : const Color(0xFFF4F1FB);
    final outline = isDark
        ? Colors.white.withOpacity(0.18)
        : const Color(0xFF7C72A8).withOpacity(0.18);
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      onPrimary: isDark ? const Color(0xFF17142B) : Colors.white,
      secondary: secondary,
      onSecondary: isDark ? const Color(0xFF102622) : Colors.white,
      surface: base,
      onSurface: foreground,
      error: isDark ? const Color(0xFFFF858E) : const Color(0xFFB32635),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: ColoredBox(
              color:
                  (isDark ? const Color(0xFF17182D) : const Color(0xFFF8F5FF))
                      .withOpacity(0.42),
            ),
          ),
        ),
        iconTheme: IconThemeData(color: foreground),
        titleTextStyle: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: foreground,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.all(4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: outline),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary.withOpacity(isDark ? 0.82 : 0.90),
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: primary.withOpacity(0.24),
          disabledForegroundColor: foreground.withOpacity(0.48),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const StadiumBorder(),
          side: BorderSide(color: Colors.white.withOpacity(0.34)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: const StadiumBorder(),
          side: BorderSide(color: primary.withOpacity(0.42)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: foreground,
          backgroundColor: Colors.white.withOpacity(isDark ? 0.07 : 0.42),
          shape: const CircleBorder(),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: (isDark ? Colors.white : primary)
            .withOpacity(isDark ? 0.08 : 0.055),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        labelStyle: TextStyle(color: muted),
        hintStyle: TextStyle(color: muted.withOpacity(0.82)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.14),
      ),
      dividerTheme: DividerThemeData(
        color: outline.withOpacity(0.7),
        thickness: 0.7,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? const Color(0xFF29283E) : const Color(0xFF322D50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
