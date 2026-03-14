import 'package:flutter/material.dart';

abstract class IronRepColors {
  static const Color trueBlack = Color(0xFF000000);
  static const Color oledBackground = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color card = Color(0xFF1C1C1E);
  static const Color elevated = Color(0xFF2C2C2E);
  static const Color accent = Color(0xFFFF6B35);
  static const Color accentDim = Color(0x40FF6B35);
  static const Color success = Color(0xFF34C759);
  static const Color successDim = Color(0x4034C759);
  static const Color error = Color(0xFFFF453A);
  static const Color warning = Color(0xFFFFD60A);
  static const Color divider = Color(0xFF1E1E1E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textMuted = Color(0xFF48484A);
}

abstract class IronRepSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 16);
}

abstract class IronRepTheme {
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: IronRepColors.oledBackground,
        colorScheme: ColorScheme.dark(
          surface: IronRepColors.surface,
          primary: IronRepColors.accent,
          secondary: IronRepColors.accent,
          error: IronRepColors.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: IronRepColors.oledBackground,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: IronRepColors.textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          color: IronRepColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: IronRepColors.trueBlack,
          selectedItemColor: IronRepColors.accent,
          unselectedItemColor: IronRepColors.textMuted,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: IronRepColors.elevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintStyle: const TextStyle(color: IronRepColors.textMuted),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: IronRepColors.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          },
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: IronRepColors.textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: IronRepColors.textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: IronRepColors.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: IronRepColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: IronRepColors.textSecondary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: IronRepColors.textSecondary,
          ),
          labelSmall: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: IronRepColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      );
}
