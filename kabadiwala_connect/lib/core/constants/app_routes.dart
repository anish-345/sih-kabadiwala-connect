/// All named route paths in one place — prevents magic strings.
abstract final class AppRoutes {
  // Onboarding
  static const language    = '/';
  static const role        = '/role';
  static const walkthrough = '/walkthrough';

  // Auth
  static const login = '/login';
  static const otp   = '/otp';

  // Collector shell
  static const scanner    = '/scanner';
  static const priceBoard = '/prices';
  static const earnings   = '/earnings';
  static const safety     = '/safety';

  // Lot flow
  static const lotDetail = '/lot/:lotId';
  static const qrDisplay = '/lot/:lotId/qr';

  // Handover
  static const handoverScan    = '/handover/scan';
  static const handoverConfirm = '/handover/:traceId';

  // Recycler
  static const recyclerDash = '/recycler';
}
