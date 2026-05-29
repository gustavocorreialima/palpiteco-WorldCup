import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
  static TextStyle _inter(double size, FontWeight weight, {Color color = AppColors.textPrimary, double? height, double? letterSpacing}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: letterSpacing);

  // Display
  static TextStyle get display      => _inter(36, FontWeight.w800, letterSpacing: -1.5, height: 1.1);
  static TextStyle get h1           => _inter(28, FontWeight.w800, letterSpacing: -1.0);
  static TextStyle get h2           => _inter(22, FontWeight.w700, letterSpacing: -0.5);
  static TextStyle get h3           => _inter(18, FontWeight.w700);

  // Body
  static TextStyle get bodyLarge    => _inter(16, FontWeight.w500, height: 1.5);
  static TextStyle get body         => _inter(14, FontWeight.w400, height: 1.5);
  static TextStyle get bodySmall    => _inter(13, FontWeight.w400, color: AppColors.textSecondary);

  // Score
  static TextStyle get scoreHuge    => _inter(48, FontWeight.w800, letterSpacing: -2);
  static TextStyle get scoreDigit   => _inter(32, FontWeight.w800, letterSpacing: -1);
  static TextStyle get scoreVs      => _inter(16, FontWeight.w300, color: AppColors.textMuted);

  // Labels
  static TextStyle get label        => _inter(12, FontWeight.w600, letterSpacing: 0.8, color: AppColors.textSecondary);
  static TextStyle get labelNeon    => _inter(11, FontWeight.w700, letterSpacing: 1.5);
  static TextStyle get caption      => _inter(11, FontWeight.w400, color: AppColors.textSecondary);

  // Teams
  static TextStyle get teamName     => _inter(14, FontWeight.w700, height: 1.3);
  static TextStyle get teamNameSm   => _inter(12, FontWeight.w600);

  // Ranking
  static TextStyle get rankPosition => _inter(20, FontWeight.w800, letterSpacing: -0.5);
  static TextStyle get rankPoints   => _inter(15, FontWeight.w700, color: AppColors.neonBlue);

  // Button
  static TextStyle get button       => _inter(15, FontWeight.w700, letterSpacing: 0.3);
  static TextStyle get buttonSm     => _inter(13, FontWeight.w600);
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
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
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
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
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
