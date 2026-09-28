import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/core/utils/qr_signer.dart';

void main() {
  group('QrSigner HMAC Cryptographic Protocol (PS 26229 Spec 05)', () {
    test('buildPayload creates valid JSON with required fields', () {
      final payload = QrSigner.buildPayload(
        txId: 'TX-TEST-001',
        lotId: 'LOT-TEST-001',
        collectorId: 'COLL-001',
        lat: 18.5204,
        lon: 73.8567,
        category: 'PCB',
        subCategory: 'Mid Grade',
        estWeightKg: 20.0,
        quotedValueInr: 3800.0,
        netOfferedPriceInr: 3800.0,
      );

      final map = jsonDecode(payload) as Map<String, dynamic>;
      expect(map['tx_id'], equals('TX-TEST-001'));
      expect(map['lot_id'], equals('LOT-TEST-001'));
      expect(map['material']['category'], equals('PCB'));
      expect(map['price']['net_offered_price_inr'], equals(3800.0));
      expect(map['expires_at'], isNotNull);
    });

    test('sign and verify roundtrip succeeds', () {
      final payload = QrSigner.buildPayload(
        txId: 'TX-TEST-002',
        lotId: 'LOT-TEST-002',
        collectorId: 'COLL-002',
        lat: 18.6279,
        lon: 73.8131,
        category: 'Cables',
        subCategory: 'Heavy Copper',
        estWeightKg: 10.0,
        quotedValueInr: 4600.0,
        netOfferedPriceInr: 4600.0,
      );

      final signedBlob = QrSigner.sign(payload);
      final result = QrSigner.verify(signedBlob);

      expect(result.valid, isTrue);
      expect(result.error, isNull);
      expect(result.payload?['tx_id'], equals('TX-TEST-002'));
      expect(result.payload?['lot_id'], equals('LOT-TEST-002'));
    });

    test('tampered payload is detected and rejected', () {
      final payload = QrSigner.buildPayload(
        txId: 'TX-TEST-003',
        lotId: 'LOT-TEST-003',
        collectorId: 'COLL-003',
        lat: 18.5204,
        lon: 73.8567,
        category: 'PCB',
        subCategory: 'Mid Grade',
        estWeightKg: 20.0,
        quotedValueInr: 3800.0,
        netOfferedPriceInr: 3800.0,
      );

      final signedBlob = QrSigner.sign(payload);
      final outer = jsonDecode(signedBlob) as Map<String, dynamic>;

      // Tamper by modifying payload
      final tamperedPayload = base64Encode(utf8.encode('{"tampered":true}'));
      final tamperedBlob = jsonEncode({
        'format': outer['format'],
        'payload': tamperedPayload,
        'signature': outer['signature'],
      });

      final result = QrSigner.verify(tamperedBlob);
      expect(result.valid, isFalse);
      expect(result.error, contains('mismatch'));
    });

    test('expired token is rejected', () {
      // Create payload that expired 1 hour ago
      final expiredNow = DateTime.now().millisecondsSinceEpoch - 3600000;
      final payload = jsonEncode({
        'tx_id': 'TX-EXPIRED',
        'lot_id': 'LOT-EXPIRED',
        'timestamp': expiredNow - 86400000,
        'expires_at': expiredNow,
      });

      final signedBlob = QrSigner.sign(payload);
      final result = QrSigner.verify(signedBlob);

      expect(result.valid, isFalse);
      expect(result.error, contains('expired'));
    });
  });
}
