/// Central Application Configuration for Kabadiwala Connect
/// Supports dynamic build-time injection via --dart-define=BACKEND_URL=...
class AppConfig {
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://sih-anishs-projects-886cd6a4.vercel.app',
  );

  /// Resolved API Base URL without trailing slash
  static String get apiBaseUrl {
    final clean = backendUrl.replaceAll(RegExp(r'/+$'), '');
    return clean.endsWith('/api') ? clean : '$clean/api';
  }

  /// Central AI Inference endpoint (Fireworks AI Vision proxy)
  static String get aiClassifyUrl => '$apiBaseUrl/ai/classify';

  /// Central Outbox / Inbound CPCB Audit Ledger Sync endpoint
  static String get syncUrl => '$apiBaseUrl/sync';

  /// Central Health endpoint
  static String get healthUrl => '$apiBaseUrl/health';

  /// Rates endpoint
  static String get pricesUrl => '$apiBaseUrl/prices';
}
