import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Cryptographically verifiable QR handover signing and verification.
/// Uses HMAC-SHA256 with tamper-evident payload, photo hash, GPS, timestamp and lot metadata.
class QrSigner {
  static const String _secretSeed = 'SIH2026-JNARDDC-MINES-EWASTE-TRUST-LEDGER-V1';

  /// Sign QR payload with HMAC-SHA256 and package into transport JSON blob.
  static String sign(String payloadJson, [String secret = _secretSeed]) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(payloadJson);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    final signatureB64 = base64Encode(digest.bytes);
    final payloadB64 = base64Encode(bytes);

    return jsonEncode({
      'format': 'KABADIWALA_TRACE_V1',
      'payload': payloadB64,
      'signature': signatureB64,
      'algorithm': 'HMAC-SHA256',
    });
  }

  /// Verify a signed QR blob. Returns verification status and decoded payload.
  static ({bool valid, Map<String, dynamic>? payload, String? error}) verify(
    String signedBlob, [
    String secret = _secretSeed,
  ]) {
    try {
      final outer = jsonDecode(signedBlob) as Map<String, dynamic>;
      final payloadB64 = outer['payload'] as String?;
      final signatureB64 = outer['signature'] as String?;

      if (payloadB64 == null || signatureB64 == null) {
        return (valid: false, payload: null, error: 'Malformed QR payload structure');
      }

      final payloadBytes = base64Decode(payloadB64);
      final key = utf8.encode(secret);
      final hmac = Hmac(sha256, key);
      final expectedDigest = hmac.convert(payloadBytes);
      final expectedSignature = base64Encode(expectedDigest.bytes);

      if (expectedSignature != signatureB64) {
        return (valid: false, payload: null, error: 'Cryptographic signature mismatch: tamper detected');
      }

      final payloadJson = utf8.decode(payloadBytes);
      final data = jsonDecode(payloadJson) as Map<String, dynamic>;

      final expiresAt = data['expires_at'] as int? ?? 0;
      if (expiresAt > 0 && DateTime.now().millisecondsSinceEpoch > expiresAt) {
        return (valid: false, payload: null, error: 'Handover token expired (>24 hours old)');
      }

      return (valid: true, payload: data, error: null);
    } catch (e) {
      return (valid: false, payload: null, error: 'Failed to parse QR token: $e');
    }
  }

  /// Build a verifiable handover payload matching CPCB / JNARDDC traceability spec.
  static String buildPayload({
    required String txId,
    required String lotId,
    required String collectorId,
    required double lat,
    required double lon,
    required String category,
    required String subCategory,
    required double estWeightKg,
    required double quotedValueInr,
    required double netOfferedPriceInr,
    String? photoHash,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return jsonEncode({
      'tx_id': txId,
      'lot_id': lotId,
      'collector_id': collectorId,
      'timestamp': now,
      'expires_at': now + 86400000, // 24 hours
      'lat': lat,
      'lon': lon,
      'photo_hash': photoHash ?? sha256.convert(utf8.encode('$lotId:$now')).toString().substring(0, 16),
      'material': {
        'category': category,
        'sub_category': subCategory,
        'est_weight_kg': estWeightKg,
      },
      'price': {
        'quoted_value_inr': quotedValueInr,
        'net_offered_price_inr': netOfferedPriceInr,
      },
    });
  }
}
