import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/core/utils/density_fraud_detector.dart';

void main() {
  group('DensityFraudDetector Tests (PS 26229 Spec 07)', () {
    test('returns clean for zero or negative weight', () {
      final res = DensityFraudDetector.analyse(
        bbox: [10, 10, 100, 100],
        frameW: 480,
        frameH: 640,
        weightKg: 0.0,
        subCategory: 'pcb',
      );
      expect(res.severity, equals(FraudSeverity.clean));
    });

    test('returns clean for realistic PCB motherboard density', () {
      final res = DensityFraudDetector.analyse(
        bbox: [40, 60, 400, 480],
        frameW: 480,
        frameH: 640,
        weightKg: 43.0,
        subCategory: 'motherboard',
      );
      expect(res.severity, isNot(equals(FraudSeverity.flag)));
    });

    test('flags anomaly when weight is excessively high for small volume', () {
      // 500 kg for a tiny 20x20 pixel bounding box
      final res = DensityFraudDetector.analyse(
        bbox: [100, 100, 120, 120],
        frameW: 480,
        frameH: 640,
        weightKg: 500.0,
        subCategory: 'motherboard',
      );
      expect(res.severity, equals(FraudSeverity.flag));
      expect(res.message, isNotNull);
    });
  });
}
