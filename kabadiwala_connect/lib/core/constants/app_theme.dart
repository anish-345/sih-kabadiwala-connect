import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────

abstract final class AppColors {
  // Surfaces
  static const bg = Color(0xFFFAFAF9);
  static const surface = Color(0xFFFFFFFF);

  // Text
  static const ink = Color(0xFF171717);
  static const muted = Color(0xFF737373);
  static const subtle = Color(0xFFA3A3A3);

  // Borders
  static const line = Color(0xFFE5E5E5);
  static const lineSoft = Color(0xFFF5F5F4);

  // Primary (Emerald)
  static const accent = Color(0xFF059669);
  static const accentMuted = Color(0xFF047857);
  static const accentSoft = Color(0xFFECFDF5);
  static const accentBorder = Color(0xFFA7F3D0);

  // Semantic
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFEF2F2);
  static const dangerBorder = Color(0xFFFECACA);
  static const warn = Color(0xFFD97706);
  static const warnSoft = Color(0xFFFFFBEB);
  static const warnBorder = Color(0xFFFDE68A);
  static const info = Color(0xFF2563EB);
  static const infoSoft = Color(0xFFEFF6FF);
  static const infoBorder = Color(0xFFBFDBFE);
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 100;
}

// ── Theme ─────────────────────────────────────────────────────────────────────

abstract final class AppTheme {
  static ThemeData get light {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        onPrimary: Colors.white,
        secondary: AppColors.ink,
        onSecondary: Colors.white,
        error: AppColors.danger,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        outline: AppColors.line,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
            fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.8,
            color: AppColors.ink),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
            fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5,
            color: AppColors.ink),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
            fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3,
            color: AppColors.ink),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
            fontSize: 18, fontWeight: FontWeight.w600,
            color: AppColors.ink),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
            fontSize: 17, fontWeight: FontWeight.w600,
            color: AppColors.ink),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
            fontSize: 15, fontWeight: FontWeight.w500,
            color: AppColors.ink),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
            fontSize: 15, fontWeight: FontWeight.w400, height: 1.5,
            color: AppColors.ink),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
            fontSize: 13, fontWeight: FontWeight.w400, height: 1.5,
            color: AppColors.muted),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: AppColors.ink),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
            fontSize: 12, fontWeight: FontWeight.w500,
            color: AppColors.muted),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
            fontSize: 11, fontWeight: FontWeight.w500,
            color: AppColors.subtle),
      ),
      dividerColor: AppColors.line,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          elevation: 0,
          side: const BorderSide(color: AppColors.line),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
              Radius.circular(AppRadius.lg)),
          side: BorderSide(color: AppColors.line),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
          letterSpacing: -0.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accentSoft,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.accent : AppColors.muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? AppColors.accent : AppColors.muted,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
      ),
      extensions: const [KabadiwalaColors()],
    );
  }

  static ThemeData get dark => light;
}

class KabadiwalaColors extends ThemeExtension<KabadiwalaColors> {
  const KabadiwalaColors({
    this.fraudFlag = AppColors.danger,
    this.fraudWarn = AppColors.warn,
    this.eprGreen = AppColors.accent,
    this.ncmmBlue = AppColors.info,
    this.pendingAmber = AppColors.warn,
  });

  final Color fraudFlag;
  final Color fraudWarn;
  final Color eprGreen;
  final Color ncmmBlue;
  final Color pendingAmber;

  @override
  KabadiwalaColors copyWith({
    Color? fraudFlag,
    Color? fraudWarn,
    Color? eprGreen,
    Color? ncmmBlue,
    Color? pendingAmber,
  }) =>
      KabadiwalaColors(
        fraudFlag: fraudFlag ?? this.fraudFlag,
        fraudWarn: fraudWarn ?? this.fraudWarn,
        eprGreen: eprGreen ?? this.eprGreen,
        ncmmBlue: ncmmBlue ?? this.ncmmBlue,
        pendingAmber: pendingAmber ?? this.pendingAmber,
      );

  @override
  KabadiwalaColors lerp(KabadiwalaColors? other, double t) => this;
}
