import 'package:flutter/material.dart';

class WasabiColors {
  const WasabiColors._();

  static const primary = Color(0xFF678F07);
  static const secondary = Color(0xFFE98F01);
  static const background = Color(0xFFFFFADD);
  static const dark = Color(0xFF141414);
  static const surface = Color(0xFFFFFFFF);
  static const muted = Color(0xFF767676);
  static const stroke = Color(0xFFEDE6BF);

  static const darkBackground = Color(0xFF090909);
  static const darkSurface = Color(0xFF10140D);
  static const darkSurfaceHigh = Color(0xFF17210F);
  static const darkText = Color(0xFFF7F9EF);
  static const darkMuted = Color(0xFFB5BEA5);
  static const darkStroke = Color(0xFF39432B);
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: WasabiColors.primary,
        primary: WasabiColors.primary,
        secondary: WasabiColors.secondary,
        surface: WasabiColors.surface,
      ),
    );

    return base.copyWith(
      splashFactory: InkRipple.splashFactory,
      scaffoldBackgroundColor: WasabiColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: WasabiColors.background,
        foregroundColor: WasabiColors.dark,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: WasabiColors.primary,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: 0,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: WasabiColors.surface,
        indicatorColor: WasabiColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? WasabiColors.primary
                : WasabiColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? WasabiColors.primary
                : WasabiColors.muted,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: WasabiColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFF3F4F6)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WasabiColors.surface,
        hintStyle: const TextStyle(color: WasabiColors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WasabiColors.primary, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: WasabiColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(48, 52),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: WasabiColors.dark,
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(48, 52),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: WasabiColors.surface,
        selectedColor: WasabiColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: WasabiColors.primary,
        brightness: Brightness.dark,
        primary: WasabiColors.primary,
        secondary: WasabiColors.secondary,
        surface: WasabiColors.darkSurface,
      ),
    );

    return base.copyWith(
      splashFactory: InkRipple.splashFactory,
      scaffoldBackgroundColor: WasabiColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: WasabiColors.darkBackground,
        foregroundColor: WasabiColors.darkText,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: WasabiColors.primary,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: 0,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: WasabiColors.darkSurface,
        indicatorColor: WasabiColors.primary.withValues(alpha: 0.22),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? WasabiColors.primary
                : WasabiColors.darkMuted,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? WasabiColors.primary
                : WasabiColors.darkMuted,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: WasabiColors.darkSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: WasabiColors.darkStroke),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WasabiColors.darkSurfaceHigh,
        hintStyle: const TextStyle(color: WasabiColors.darkMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WasabiColors.darkStroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WasabiColors.darkStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WasabiColors.primary, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: WasabiColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(48, 52),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: WasabiColors.darkText,
          side: const BorderSide(color: WasabiColors.darkStroke),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(48, 52),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: WasabiColors.darkSurface,
        selectedColor: WasabiColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
        side: const BorderSide(color: WasabiColors.darkStroke),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}
