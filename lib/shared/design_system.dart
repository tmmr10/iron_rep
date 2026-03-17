import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Theme-aware color system (replaces static IronRepColors)
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface;
  final Color card;
  final Color elevated;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color accentDim;
  final Color success;
  final Color successDim;
  final Color error;
  final Color warning;
  final Color divider;
  final Color glassOverlay;
  final Color glassBorder;
  final Color accentGradientStart;
  final Color accentGradientEnd;
  final Color statIconColor;

  const AppColors({
    required this.background,
    required this.surface,
    required this.card,
    required this.elevated,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentDim,
    required this.success,
    required this.successDim,
    required this.error,
    required this.warning,
    required this.divider,
    required this.glassOverlay,
    required this.glassBorder,
    required this.accentGradientStart,
    required this.accentGradientEnd,
    required this.statIconColor,
  });

  static const dark = AppColors(
    background: Color(0xFF050505),
    surface: Color(0xFF0F0F12),
    card: Color(0xFF141418),
    elevated: Color(0xFF1C1C22),
    border: Color(0xFF2A2A30),
    textPrimary: Color(0xFFF0F0F5),
    textSecondary: Color(0xFF8E8E96),
    textMuted: Color(0xFF48484F),
    accent: Color(0xFFCCFF00),       // Lime — vibrant accent
    accentDim: Color(0x20CCFF00),
    success: Color(0xFF34D399),      // Emerald-400
    successDim: Color(0xFF0D2818),
    error: Color(0xFFF87171),        // Red-400
    warning: Color(0xFFFBBF24),      // Amber-400
    divider: Color(0xFF1E1E24),
    glassOverlay: Color(0x14FFFFFF),
    glassBorder: Color(0x18FFFFFF),
    accentGradientStart: Color(0xFFCCFF00), // Lime
    accentGradientEnd: Color(0xFF9AE600),   // Darker Lime
    statIconColor: Color(0xFFFF8C00),       // Orange
  );

  static const light = AppColors(
    background: Color(0xFFF5F5F7),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    elevated: Color(0xFFF0F0F2),
    border: Color(0xFFE0E0E2),
    textPrimary: Color(0xFF1A1A1C),
    textSecondary: Color(0xFF6B6B70),
    textMuted: Color(0xFFB0B0B5),
    accent: Color(0xFFA3CC00),
    accentDim: Color(0x20A3CC00),
    success: Color(0xFF22C55E),
    successDim: Color(0xFFDCFCE7),
    error: Color(0xFFEF4444),
    warning: Color(0xFFF59E0B),
    divider: Color(0xFFE8E8EA),
    glassOverlay: Color(0x10000000),
    glassBorder: Color(0x15000000),
    accentGradientStart: Color(0xFFA3CC00),
    accentGradientEnd: Color(0xFF7DA300),
    statIconColor: Color(0xFFE07800),       // Orange (light)
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? elevated,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? accentDim,
    Color? success,
    Color? successDim,
    Color? error,
    Color? warning,
    Color? divider,
    Color? glassOverlay,
    Color? glassBorder,
    Color? accentGradientStart,
    Color? accentGradientEnd,
    Color? statIconColor,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      elevated: elevated ?? this.elevated,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accentDim: accentDim ?? this.accentDim,
      success: success ?? this.success,
      successDim: successDim ?? this.successDim,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      divider: divider ?? this.divider,
      glassOverlay: glassOverlay ?? this.glassOverlay,
      glassBorder: glassBorder ?? this.glassBorder,
      accentGradientStart: accentGradientStart ?? this.accentGradientStart,
      accentGradientEnd: accentGradientEnd ?? this.accentGradientEnd,
      statIconColor: statIconColor ?? this.statIconColor,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentDim: Color.lerp(accentDim, other.accentDim, t)!,
      success: Color.lerp(success, other.success, t)!,
      successDim: Color.lerp(successDim, other.successDim, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      glassOverlay: Color.lerp(glassOverlay, other.glassOverlay, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      accentGradientStart:
          Color.lerp(accentGradientStart, other.accentGradientStart, t)!,
      accentGradientEnd:
          Color.lerp(accentGradientEnd, other.accentGradientEnd, t)!,
      statIconColor: Color.lerp(statIconColor, other.statIconColor, t)!,
    );
  }
}

abstract class IronRepGradients {
  static LinearGradient accent(AppColors c) => LinearGradient(
        colors: [c.accentGradientStart, c.accentGradientEnd],
      );

  static LinearGradient cardGlow(Color color) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [color.withValues(alpha: 0.08), Colors.transparent],
      );
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
  /// Call once before runApp to prevent network font downloads on real devices.
  static void init() {
    GoogleFonts.config.allowRuntimeFetching = false;
  }

  static ThemeData _buildTheme(AppColors colors, Brightness brightness) {
    final base = ThemeData(brightness: brightness);
    final spaceGrotesk = GoogleFonts.spaceGroteskTextTheme(base.textTheme);
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      extensions: [colors],
      colorScheme: ColorScheme(
        brightness: brightness,
        surface: colors.surface,
        primary: colors.accent,
        secondary: colors.accent,
        error: colors.error,
        onSurface: colors.textPrimary,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.background,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colors.accent,
            );
          }
          return TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: colors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colors.accent, size: 24);
          }
          return IconThemeData(color: colors.textMuted, size: 24);
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.background,
        selectedItemColor: colors.textPrimary,
        unselectedItemColor: colors.textMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
        floatingLabelStyle: TextStyle(color: colors.accent, fontSize: 13),
        labelStyle: TextStyle(color: colors.textMuted, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: colors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.black.withValues(alpha: 0.4);
            }
            return Colors.black;
          }),
          elevation: WidgetStateProperty.all(0),
          shadowColor: WidgetStateProperty.all(colors.accent.withValues(alpha: 0.3)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          backgroundBuilder: (context, states, child) {
            final isDisabled = states.contains(WidgetState.disabled);
            final isPressed = states.contains(WidgetState.pressed);
            return AnimatedOpacity(
              opacity: isPressed ? 0.8 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: AnimatedScale(
                scale: isPressed ? 0.97 : 1.0,
                duration: const Duration(milliseconds: 100),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDisabled
                          ? [
                              colors.accentGradientStart.withValues(alpha: 0.4),
                              colors.accentGradientEnd.withValues(alpha: 0.4),
                            ]
                          : [colors.accentGradientStart, colors.accentGradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isDisabled
                        ? []
                        : [
                            BoxShadow(
                              color: colors.accent.withValues(alpha: isPressed ? 0.1 : 0.2),
                              blurRadius: isPressed ? 6 : 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colors.textMuted;
            }
            return colors.textSecondary;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return BorderSide(color: colors.accent, width: 1.5);
            }
            return BorderSide(color: colors.border, width: 1);
          }),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          overlayColor: WidgetStateProperty.all(
            colors.accent.withValues(alpha: 0.08),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colors.textMuted;
            }
            if (states.contains(WidgetState.pressed)) {
              return colors.accent;
            }
            return colors.textSecondary;
          }),
          overlayColor: WidgetStateProperty.all(
            colors.accent.withValues(alpha: 0.08),
          ),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
      fontFamily: spaceGrotesk.bodyMedium?.fontFamily,
      textTheme: spaceGrotesk.copyWith(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: colors.textSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: colors.textSecondary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: colors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: colors.textMuted,
          letterSpacing: 1.2,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 0.5,
      ),
    );
  }

  static ThemeData get darkTheme => _buildTheme(AppColors.dark, Brightness.dark);
  static ThemeData get lightTheme => _buildTheme(AppColors.light, Brightness.light);
}
