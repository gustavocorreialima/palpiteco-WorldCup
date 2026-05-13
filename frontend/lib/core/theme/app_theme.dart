import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ===========================================================================
// BOLÃO 2026 — PREMIUM DARK NEON PALETTE
// ===========================================================================
abstract final class AppColors {
  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const background     = Color(0xFF081220);  // deepest blue-black
  static const bgSecondary    = Color(0xFF0D1B2E);  // cards bg base
  static const card           = Color(0xFF111827);  // card surface
  static const cardGlass      = Color(0x1A2563FF);  // blue glass tint
  static const cardBorder     = Color(0x262563FF);  // blue border glow

  // ── Brand / Neon ───────────────────────────────────────────────────────────
  static const neonBlue       = Color(0xFF2563FF);  // primary CTA neon
  static const neonBlueDark   = Color(0xFF1D4ED8);
  static const neonGreen      = Color(0xFF00FFB2);  // success / live
  static const neonGreenDark  = Color(0xFF00CC8E);
  static const liveRed        = Color(0xFFFF3B3B);  // AO VIVO badge
  static const purple         = Color(0xFF7C3AED);  // secondary accent
  static const gold           = Color(0xFFFFB800);  // top 3 / medals

  // ── Text ───────────────────────────────────────────────────────────────────
  static const textPrimary    = Color(0xFFFFFFFF);
  static const textSecondary  = Color(0xFFB8BBC9);
  static const textMuted      = Color(0xFF4A5568);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const winHome        = Color(0xFF2563FF);
  static const winAway        = Color(0xFFFF3B3B);
  static const drawColor      = Color(0xFF6B7280);

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const gradientBg = LinearGradient(
    colors: [Color(0xFF081220), Color(0xFF0D1B2E), Color(0xFF081220)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientNeonBlue = LinearGradient(
    colors: [Color(0xFF2563FF), Color(0xFF7C3AED)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const gradientCard = LinearGradient(
    colors: [Color(0xFF111827), Color(0xFF0D1B2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientHero = LinearGradient(
    colors: [Colors.transparent, Color(0x33000000), Color(0xCC081220)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );

  // ── Glow Shadows ───────────────────────────────────────────────────────────
  static List<BoxShadow> glowBlue({double intensity = 0.4}) => [
        BoxShadow(color: neonBlue.withOpacity(intensity), blurRadius: 20, spreadRadius: -4),
        BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8)),
      ];

  static List<BoxShadow> glowGreen({double intensity = 0.4}) => [
        BoxShadow(color: neonGreen.withOpacity(intensity), blurRadius: 20, spreadRadius: -4),
        BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8)),
      ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 24, offset: const Offset(0, 8)),
    BoxShadow(color: neonBlue.withOpacity(0.08), blurRadius: 32, spreadRadius: -8),
  ];
}

// ===========================================================================
// TEXT STYLES
// ===========================================================================
abstract final class AppTextStyles {
  static const _base = TextStyle(fontFamily: 'Inter', color: AppColors.textPrimary);

  // Display
  static final display      = _base.copyWith(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.5, height: 1.1);
  static final h1           = _base.copyWith(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1.0);
  static final h2           = _base.copyWith(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5);
  static final h3           = _base.copyWith(fontSize: 18, fontWeight: FontWeight.w700);

  // Body
  static final bodyLarge    = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5);
  static final body         = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static final bodySmall    = _base.copyWith(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary);

  // Score
  static final scoreHuge    = _base.copyWith(fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -2);
  static final scoreDigit   = _base.copyWith(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1);
  static final scoreVs      = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w300, color: AppColors.textMuted);

  // Labels
  static final label        = _base.copyWith(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: AppColors.textSecondary);
  static final labelNeon    = _base.copyWith(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5);
  static final caption      = _base.copyWith(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textSecondary);

  // Teams
  static final teamName     = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w700, height: 1.3);
  static final teamNameSm   = _base.copyWith(fontSize: 12, fontWeight: FontWeight.w600);

  // Ranking
  static final rankPosition = _base.copyWith(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5);
  static final rankPoints   = _base.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.neonBlue);

  // Button
  static final button       = _base.copyWith(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3);
  static final buttonSm     = _base.copyWith(fontSize: 13, fontWeight: FontWeight.w600);
}

// ===========================================================================
// SPACING / RADIUS
// ===========================================================================
abstract final class AppSpacing {
  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 16.0;
  static const lg  = 24.0;
  static const xl  = 32.0;
  static const xxl = 48.0;
}

abstract final class AppRadius {
  static const sm  = 8.0;
  static const md  = 16.0;
  static const lg  = 20.0;
  static const xl  = 28.0;
  static const full = 999.0;
}

// ===========================================================================
// THEME DATA
// ===========================================================================
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary:    AppColors.neonBlue,
      secondary:  AppColors.neonGreen,
      tertiary:   AppColors.purple,
      surface:    AppColors.card,
      error:      AppColors.liveRed,
      onPrimary:  AppColors.textPrimary,
      onSurface:  AppColors.textPrimary,
    ),
    fontFamily: 'Inter',
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.neonBlue, width: 1.5),
      ),
      labelStyle: AppTextStyles.caption,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.neonBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: AppTextStyles.button,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.neonBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: AppTextStyles.button,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.cardBorder,
      thickness: 0.5,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: AppColors.neonBlue,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    tabBarTheme: TabBarThemeData(
      indicatorColor: AppColors.neonBlue,
      labelColor: AppColors.textPrimary,
      unselectedLabelColor: AppColors.textMuted,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: AppTextStyles.buttonSm,
      unselectedLabelStyle: AppTextStyles.buttonSm,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.card,
      selectedColor: AppColors.neonBlue.withOpacity(0.2),
      labelStyle: AppTextStyles.caption,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
    ),
  );
}

// ===========================================================================
// GRADIENT BACKGROUND WIDGET
// ===========================================================================
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.gradientBg),
      child: child,
    );
  }
}
