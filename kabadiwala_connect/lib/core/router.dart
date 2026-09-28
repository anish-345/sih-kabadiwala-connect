import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/otp_screen.dart';
import '../features/onboarding/presentation/screens/language_screen.dart';
import '../features/onboarding/presentation/screens/role_screen.dart';
import '../features/onboarding/presentation/screens/walkthrough_screen.dart';
import '../features/scanner/presentation/screens/scanner_screen.dart';
import '../features/price_board/presentation/screens/price_board_screen.dart';
import '../features/lot_creation/presentation/screens/lot_detail_screen.dart';
import '../features/lot_creation/presentation/screens/qr_display_screen.dart';
import '../features/handover/presentation/screens/handover_scan_screen.dart';
import '../features/handover/presentation/screens/handover_confirm_screen.dart';
import '../features/earnings/presentation/screens/earnings_screen.dart';
import '../features/safety/presentation/screens/safety_screen.dart';
import '../features/recycler_dash/presentation/screens/recycler_dashboard_screen.dart';
import 'constants/app_routes.dart';
import 'widgets/home_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.language,
    debugLogDiagnostics: false,
    routes: [
      // ── Onboarding ───────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.language,
        builder: (ctx, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: AppRoutes.role,
        builder: (ctx, state) => const RoleScreen(),
      ),
      GoRoute(
        path: AppRoutes.walkthrough,
        builder: (ctx, state) => const WalkthroughScreen(),
      ),

      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (ctx, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (ctx, state) => OtpScreen(
          phone: (state.extra as String?) ?? '98221 44021',
        ),
      ),

      // ── Collector shell (bottom nav) ─────────────────────────────────────
      ShellRoute(
        builder: (ctx, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.scanner,
            builder: (ctx, state) => const ScannerScreen(),
          ),
          GoRoute(
            path: AppRoutes.priceBoard,
            builder: (ctx, state) => const PriceBoardScreen(),
          ),
          GoRoute(
            path: AppRoutes.earnings,
            builder: (ctx, state) => const EarningsScreen(),
          ),
          GoRoute(
            path: AppRoutes.safety,
            builder: (ctx, state) => const SafetyScreen(),
          ),
        ],
      ),

      // ── Lot flow ─────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.lotDetail,
        builder: (ctx, state) => LotDetailScreen(
          lotId: state.pathParameters['lotId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.qrDisplay,
        builder: (ctx, state) => QrDisplayScreen(
          lotId: state.pathParameters['lotId']!,
        ),
      ),

      // ── Handover ─────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.handoverScan,
        builder: (ctx, state) => HandoverScanScreen(
          initialQrBlob: state.extra as String?,
        ),
      ),
      GoRoute(
        path: AppRoutes.handoverConfirm,
        builder: (ctx, state) => HandoverConfirmScreen(
          traceId: state.pathParameters['traceId']!,
        ),
      ),

      // ── Recycler dashboard ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.recyclerDash,
        builder: (ctx, state) => const RecyclerDashboardScreen(),
      ),
    ],
  );
});
