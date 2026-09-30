import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_theme.dart';
import 'core/providers/app_state.dart';
import 'core/router.dart';
import 'l10n/app_localizations.dart';

class KabadiwalaApp extends ConsumerWidget {
  const KabadiwalaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final user = ref.watch(appStateProvider);

    return MaterialApp.router(
      title: 'Kabadiwala Connect',
      debugShowCheckedModeBanner: false,

      // ── Theming ────────────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.light,
      themeMode: ThemeMode.light,
      locale: Locale(user.language),

      // ── Routing ────────────────────────────────────────────
      routerConfig: router,

      // ── Localisation ───────────────────────────────────────
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('mr'),
      ],

      // ── Responsive Layout Builder ─────────────────────────
      builder: (context, child) {
        return Container(
          color: const Color(0xFF0F172A), // Dark slate aesthetic backdrop for wide desktop
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Container(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 24,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRect(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}
