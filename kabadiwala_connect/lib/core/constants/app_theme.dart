import 'package:flutter/material.dart';

abstract final class AppTheme {
  // ── Brand palette ─────────────────────────────────────────────────────────
  static const green900  = Color(0xFF1B5E20);
  static const _green700  = Color(0xFF388E3C);
  static const _green500  = Color(0xFF4CAF50);  // primary
  static const _amber600  = Color(0xFFFFB300);  // accent / EPR highlight
  static const _red600    = Color(0xFFE53935);  // error / fraud flag
  static const orange500 = Color(0xFFFF9800);  // fraud warning

  static const colorSeed = _green500;

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: colorSeed,
          primary: _green500,
          secondary: _amber600,
          error: _red600,
          brightness: Brightness.light,
        ),
        textTheme: _textTheme,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 52), // large touch target
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _green700,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
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

  static ThemeData get dark => light.copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: colorSeed,
          brightness: Brightness.dark,
        ),
      );

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
