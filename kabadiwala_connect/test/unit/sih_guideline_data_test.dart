import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SIH 2026 Problem Statement 26229 Benchmark Data Verification', () {
    test('1. Verify price feed schema and all 10 e-waste categories in prices.json', () async {
      final file = File('assets/data/prices.json');
      expect(file.existsSync(), isTrue, reason: 'assets/data/prices.json must exist');

      final content = await file.readAsString();
      final List<dynamic> list = jsonDecode(content);

      expect(list.length, equals(10), reason: 'Must contain 10 calibrated e-waste scrap grades');

      final categories = <String>{};
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        expect(map['priceRecordId'], isNotNull);
        expect(map['category'], isNotNull);
        expect(map['subCategory'], isNotNull);
        expect(map['informalBaseRate'], isA<num>());
        expect(map['formalGateRate'], isA<num>());
        expect(map['eprCreditShare'], isA<num>());
        expect(map['ncmmIncentive'], isA<num>());
        expect(map['netOfferedPrice'], isA<num>());

        // Verification of net price equation: Formal Gate + EPR + NCMM == Net Offered
        final formalGate = (map['formalGateRate'] as num).toDouble();
        final epr = (map['eprCreditShare'] as num).toDouble();
        final ncmm = (map['ncmmIncentive'] as num).toDouble();
        final net = (map['netOfferedPrice'] as num).toDouble();

        expect((formalGate + epr + ncmm - net).abs(), lessThan(0.01),
            reason: 'Net offered price must equal formal gate + EPR share + NCMM incentive');

        // Net price must always be strictly greater than informal base rate (collector surplus)
        final informal = (map['informalBaseRate'] as num).toDouble();
        expect(net, greaterThan(informal),
            reason: 'Formal marketplace price must beat informal middleman rate');

        categories.add(map['category'] as String);
      }

      // Check key SIH 26229 categories are present
      expect(categories, contains('PCB'));
      expect(categories, contains('Cables'));
      expect(categories, contains('Batteries'));
      expect(categories, contains('Displays'));
    });

    test('2. Verify CPCB authorized recyclers registry in recyclers.json', () async {
      final file = File('assets/data/recyclers.json');
      expect(file.existsSync(), isTrue, reason: 'assets/data/recyclers.json must exist');

      final content = await file.readAsString();
      final List<dynamic> list = jsonDecode(content);

      expect(list.length, greaterThanOrEqualTo(3), reason: 'At least 3 CPCB tier-1 facilities');

      for (final item in list) {
        final map = item as Map<String, dynamic>;
        expect(map['recyclerId'], startsWith('REC-'));
        expect(map['cpcbRegNumber'], startsWith('CPCB/'));
        expect(map['verificationStatus'], equals('CPCB_CERTIFIED'));
        expect(map['rating'], greaterThanOrEqualTo(4.0));
        expect(map['facilityLat'], isA<num>());
        expect(map['facilityLon'], isA<num>());
      }
    });

    test('3. Verify SIH PS 26229 Unit Economics (+136% Collector Surplus on 20kg PCB)', () async {
      final file = File('assets/data/prices.json');
      final List<dynamic> list = jsonDecode(await file.readAsString());

      final pcbRecord = list.firstWhere(
        (e) => e['subCategory'] == 'Mid Grade (Motherboards / GPUs)',
      ) as Map<String, dynamic>;

      const double weightKg = 20.0;
      final double formalRate = (pcbRecord['netOfferedPrice'] as num).toDouble(); // ₹190/kg
      final double formalPayout = weightKg * formalRate; // ₹3,800

      // Ground status-quo: 20% weight cut (16kg counted) @ ₹110/kg minus ₹150 logistics
      const double countedWeightKg = weightKg * 0.80; // 16.0 kg
      final double informalBaseRate = (pcbRecord['informalBaseRate'] as num).toDouble(); // ₹110/kg
      const double cartLogisticsCost = 150.0;
      final double statusQuoNetCash = (countedWeightKg * informalBaseRate) - cartLogisticsCost; // ₹1,610

      expect(formalPayout, equals(3800.0));
      expect(statusQuoNetCash, equals(1610.0));

      final double surplus = formalPayout - statusQuoNetCash; // +₹2,190
      final double percentGain = (surplus / statusQuoNetCash) * 100.0; // +136.02%

      expect(percentGain, greaterThan(135.0));
      expect(percentGain, lessThan(137.0));
    });

    test('4. Verify presence of GIZ field test e-waste camera photos', () {
      final dir = Directory('assets/images/test_samples');
      expect(dir.existsSync(), isTrue);

      final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.jpg')).toList();
      expect(files.length, greaterThanOrEqualTo(4),
          reason: 'Must contain at least 4 authentic GIZ e-waste camera photos');
    });

    test('5. Verify presence of SIH benchmark category images', () {
      final dir = Directory('assets/images/benchmark');
      expect(dir.existsSync(), isTrue);

      final expected = [
        'motherboard_sample.jpg',
        'copper_cable_sample.jpg',
        'battery_li_sample.jpg',
        'crt_glass_sample.jpg',
      ];

      for (final name in expected) {
        final f = File('assets/images/benchmark/$name');
        expect(f.existsSync(), isTrue, reason: '$name must exist');
        expect(f.lengthSync(), greaterThan(1000), reason: '$name must have non-zero size');
      }
    });

    test('6. Verify ONNX model and label files in assets/models', () {
      final onnxFile = File('assets/models/ewaste_yolov8n_cls.onnx');
      final labelsFile = File('assets/models/labels.json');
      final metaFile = File('assets/models/model_metadata.json');

      expect(onnxFile.existsSync(), isTrue);
      expect(labelsFile.existsSync(), isTrue);
      expect(metaFile.existsSync(), isTrue);

      expect(onnxFile.lengthSync(), greaterThan(1000000), reason: 'ONNX model must be > 1MB');

      final labels = jsonDecode(labelsFile.readAsStringSync());
      expect(labels['classes'], isNotEmpty);
    });
  });
}
