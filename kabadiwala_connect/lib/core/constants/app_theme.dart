import 'package:flutter/material.dart';

abstract final class AppTheme {
  // ── Brand palette ─────────────────────────────────────────────────────────
  static const green900  = Color(0xFF064E3B);
  static const green700  = Color(0xFF047857);
  static const _green500  = Color(0xFF059669);  // clean emerald primary
  static const _amber600  = Color(0xFFD97706);  // accent
  static const _red600    = Color(0xFFDC2626);  // error / fraud flag
  static const orange500 = Color(0xFFF59E0B);  // fraud warning

  static const colorSeed = _green500;

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: colorSeed,
          primary: _green500,
          secondary: _amber600,
          error: _red600,
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        textTheme: _textTheme,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _green500,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0F172A),
            elevation: 0,
            side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
            minimumSize: const Size(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        extensions: const [KabadiwalaColors()],
      );

  static ThemeData get dark => light;

  static const _textTheme = TextTheme(
    displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
    headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    headlineMedium:TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    titleLarge:    TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    labelLarge:    TextStyle(fontSize: 18, fontWeight: FontWeight.w600), // buttons
  );
}

/// Extra semantic colours available via Theme.of(ctx).extension<KabadiwalaColors>()
class KabadiwalaColors extends ThemeExtension<KabadiwalaColors> {
  const KabadiwalaColors({
    this.fraudFlag   = const Color(0xFFE53935),
    this.fraudWarn   = const Color(0xFFFF9800),
    this.eprGreen    = const Color(0xFF2E7D32),
    this.ncmmBlue    = const Color(0xFF1565C0),
    this.pendingAmber= const Color(0xFFFFB300),
  });

  final Color fraudFlag;
  final Color fraudWarn;
  final Color eprGreen;
  final Color ncmmBlue;
  final Color pendingAmber;

  @override
  KabadiwalaColors copyWith({
    Color? fraudFlag, Color? fraudWarn,
    Color? eprGreen, Color? ncmmBlue, Color? pendingAmber,
  }) => KabadiwalaColors(
    fraudFlag:    fraudFlag    ?? this.fraudFlag,
    fraudWarn:    fraudWarn    ?? this.fraudWarn,
    eprGreen:     eprGreen     ?? this.eprGreen,
    ncmmBlue:     ncmmBlue     ?? this.ncmmBlue,
    pendingAmber: pendingAmber ?? this.pendingAmber,
  );

  @override
  KabadiwalaColors lerp(KabadiwalaColors? other, double t) => this;
}
