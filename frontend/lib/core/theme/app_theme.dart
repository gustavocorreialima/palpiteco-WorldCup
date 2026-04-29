import 'package:flutter/material.dart';

// ===========================================================================
// COLOR PALETTE — Apple/Fintech premium, green-dark → black gradient
// ===========================================================================
abstract final class AppColors {
  // Backgrounds
  static const scaffoldTop      = Color(0xFF0D2B1A);  // deep forest green
  static const scaffoldBottom   = Color(0xFF050D08);  // near-black

  static const cardBackground   = Color(0x1AFFFFFF);  // white 10% — glassmorphism
  static const cardBorder       = Color(0x33FFFFFF);  // white 20%
  static const inputBackground  = Color(0x0DFFFFFF);  // white 5%

  // Brand
  static const accent           = Color(0xFF2ECC71);  // emerald CTA
  static const accentDark       = Color(0xFF27AE60);

  // Semantic
  static const liveGreen        = Color(0xFF2ECC71);
  static const winHome          = Color(0xFF3498DB);
  static const winAway          = Color(0xFFE74C3C);
  static const drawColor        = Color(0xFF95A5A6);

  // Text
  static const textPrimary      = Color(0xFFFFFFFF);
  static const textSecondary    = Color(0xFF8E9BAA);
  static const textMuted        = Color(0xFF4A5568);
}

// ===========================================================================
// TEXT STYLES
// ===========================================================================
abstract final class AppTextStyles {
  static const _base = TextStyle(fontFamily: 'Inter', color: AppColors.textPrimary);

  static final teamName    = _base.copyWith(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3);
  static final scoreDigit  = _base.copyWith(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1);
  static final scoreVs     = _base.copyWith(fontSize: 18, fontWeight: FontWeight.w300, color: AppColors.textSecondary);
  static final caption     = _base.copyWith(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static final sectionLabel= _base.copyWith(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5);
  static final liveBadge   = _base.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.liveGreen, letterSpacing: 1.2);
}

// ===========================================================================
// THEME DATA
// ===========================================================================
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.scaffoldBottom,
    colorScheme: const ColorScheme.dark(
      primary:   AppColors.accent,
      secondary: AppColors.accentDark,
      surface:   Color(0xFF0D2B1A),
      error:     Color(0xFFE74C3C),
    ),
    fontFamily: 'Inter',
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      labelStyle: AppTextStyles.caption,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.cardBorder,
      thickness: 0.5,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0D2B1A),
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}

// ===========================================================================
// GRADIENT SCAFFOLD BACKGROUND — reusable widget
// ===========================================================================
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.scaffoldTop, AppColors.scaffoldBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.6],
        ),
      ),
      child: child,
    );
  }
}
