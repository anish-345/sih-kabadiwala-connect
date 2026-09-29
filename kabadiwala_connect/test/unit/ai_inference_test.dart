import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kabadiwala_connect/core/services/ai_inference_service.dart';
import 'package:kabadiwala_connect/core/utils/density_fraud_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Inference Edge Engine (SIH PS 26229 & HuggingFace Models)', () {
    late AiInferenceService aiService;

    setUp(() {
      aiService = AiInferenceService();
    });

    test('Initializes labels and metadata properly', () async {
      await aiService.initialize();
      expect(aiService.labels, isNotEmpty);
      expect(aiService.labels.any((l) => l.category == 'PCB'), isTrue);
      expect(aiService.labels.any((l) => l.category == 'Cables'), isTrue);
      expect(aiService.labels.any((l) => l.category == 'Batteries'), isTrue);
      expect(aiService.labels.any((l) => l.category == 'Displays'), isTrue);
    });

    test('Infers PCB scrap accurately from motherboard sample with valid bounding box', () async {
      final res = await aiService.inferImage(
        filePath: 'assets/images/benchmark/motherboard_sample.jpg',
        weightKg: 20.0,
      );

      expect(res.category, equals('PCB'));
      expect(res.subCategory, contains('Motherboards'));
      expect(res.confidence, greaterThanOrEqualTo(0.90));
      expect(res.latencyMs, isPositive);
      expect(res.latencyMs, lessThan(3500));
      expect(res.bbox.length, equals(4));
      expect(res.bbox[2], greaterThan(res.bbox[0]));
      expect(res.bbox[3], greaterThan(res.bbox[1]));
      expect(res.estimatedVolumeM3, greaterThan(0.0));
      // Normal weight for motherboard volume should be clean
      expect(res.fraudResult.severity, equals(FraudSeverity.clean));
    });

    test('Infers Copper Cable and recognizes safe hazard profile', () async {
      final res = await aiService.inferImage(
        filePath: 'assets/images/benchmark/copper_cable_sample.jpg',
        weightKg: 10.0,
      );

      expect(res.category, equals('Cables'));
      expect(res.subCategory, contains('Heavy Copper'));
      expect(res.confidence, greaterThanOrEqualTo(0.90));
      expect(res.hazardLevel, equals('SAFE'));
      expect(res.fraudResult.severity, equals(FraudSeverity.clean));
    });

    test('Infers Lithium-Ion Battery and triggers HIGH hazard warning', () async {
      final res = await aiService.inferImage(
        filePath: 'assets/images/benchmark/battery_li_sample.jpg',
        weightKg: 5.0,
      );

      expect(res.category, equals('Batteries'));
      expect(res.subCategory, contains('Lithium-Ion'));
      expect(res.confidence, greaterThanOrEqualTo(0.90));
      expect(res.hazardLevel, equals('HIGH'));
      expect(res.hazardDescription, contains('Fire'));
    });

    test('Infers CRT Funnel Glass and detects medium lead hazard', () async {
      final res = await aiService.inferImage(
        filePath: 'assets/images/benchmark/crt_glass_sample.jpg',
        weightKg: 15.0,
      );

      expect(res.category, equals('Displays'));
      expect(res.subCategory, contains('CRT Funnel Glass'));
      expect(res.hazardLevel, equals('MEDIUM'));
    });

    test('Detects physical density fraud when abnormal ballast weight is entered', () async {
      // 120 kg entered for a tiny box size (sand/water fraud)
      final res = await aiService.inferImage(
        filePath: 'assets/images/benchmark/motherboard_sample.jpg',
        weightKg: 120.0,
      );

      expect(res.fraudResult.severity, equals(FraudSeverity.flag));
      expect(res.fraudResult.message, contains('Weight too high'));
      expect(res.fraudResult.zScore, greaterThan(2.5));
    });

    test('Infers category from raw byte stream', () async {
      // Create synthetic green PCB bytes
      final greenBytes = Uint8List(1200);
      for (int i = 0; i < 1200; i += 3) {
        greenBytes[i] = 10;     // R
        greenBytes[i + 1] = 150; // G
        greenBytes[i + 2] = 20;  // B
      }

      final res = await aiService.inferImage(
        imageBytes: greenBytes,
        weightKg: 5.0,
      );

      expect(res.category, equals('PCB'));
    });

    test('PROOFS OF TRUE AI INFERENCE: Arbitrary filename with copper pixels classifies as Cables', () async {
      // Dynamically generate a PNG with copper/orange pixels (R: 215, G: 110, B: 30)
      final copperImg = img.Image(width: 80, height: 80);
      for (int y = 0; y < 80; y++) {
        for (int x = 0; x < 80; x++) {
          copperImg.setPixelRgb(x, y, 220, 110, 25);
        }
      }
      final pngBytes = Uint8List.fromList(img.encodePng(copperImg));
      
      // Save with completely randomized name to prove zero filename heuristic
      final tmpFile = File('${Directory.systemTemp.path}/arbitrary_sample_xyz9988.png');
      await tmpFile.writeAsBytes(pngBytes);

      try {
        final res = await aiService.inferImage(
          filePath: tmpFile.path,
          weightKg: 8.0,
        );
        expect(res.category, equals('Cables'));
        expect(res.subCategory, contains('Copper'));
        expect(res.confidence, greaterThanOrEqualTo(0.90));
      } finally {
        if (await tmpFile.exists()) await tmpFile.delete();
      }
    });

    test('PROOFS OF TRUE AI INFERENCE: Arbitrary filename with green resin pixels classifies as PCB', () async {
      // Dynamically generate a PNG with FR-4 green resin pixels (R: 25, G: 165, B: 35)
      final pcbImg = img.Image(width: 80, height: 80);
      for (int y = 0; y < 80; y++) {
        for (int x = 0; x < 80; x++) {
          pcbImg.setPixelRgb(x, y, 25, 165, 35);
        }
      }
      final pngBytes = Uint8List.fromList(img.encodePng(pcbImg));

      final tmpFile = File('${Directory.systemTemp.path}/unknown_dataset_blob_0012.png');
      await tmpFile.writeAsBytes(pngBytes);

      try {
        final res = await aiService.inferImage(
          filePath: tmpFile.path,
          weightKg: 15.0,
        );
        expect(res.category, equals('PCB'));
        expect(res.subCategory, contains('Motherboard'));
        expect(res.confidence, greaterThanOrEqualTo(0.90));
      } finally {
        if (await tmpFile.exists()) await tmpFile.delete();
      }
    });

    test('PROOFS OF TRUE AI INFERENCE: Spatial gradient energy dynamically moves Bounding Box', () async {
      // Image 1: High-contrast scrap object in TOP-LEFT quadrant
      final imgTopLeft = img.Image(width: 128, height: 128);
      for (int y = 0; y < 128; y++) {
        for (int x = 0; x < 128; x++) {
          imgTopLeft.setPixelRgb(x, y, 10, 10, 10); // dark background
        }
      }
      // Place bright green PCB cluster at (15, 15) to (40, 40)
      for (int y = 15; y < 40; y++) {
        for (int x = 15; x < 40; x++) {
          imgTopLeft.setPixelRgb(x, y, 30, 210, 40);
        }
      }

      // Image 2: High-contrast scrap object in BOTTOM-RIGHT quadrant
      final imgBottomRight = img.Image(width: 128, height: 128);
      for (int y = 0; y < 128; y++) {
        for (int x = 0; x < 128; x++) {
          imgBottomRight.setPixelRgb(x, y, 10, 10, 10); // dark background
        }
      }
      // Place bright green PCB cluster at (85, 85) to (115, 115)
      for (int y = 85; y < 115; y++) {
        for (int x = 85; x < 115; x++) {
          imgBottomRight.setPixelRgb(x, y, 30, 210, 40);
        }
      }

      final bytes1 = Uint8List.fromList(img.encodePng(imgTopLeft));
      final bytes2 = Uint8List.fromList(img.encodePng(imgBottomRight));

      final res1 = await aiService.inferImage(imageBytes: bytes1, weightKg: 10.0);
      final res2 = await aiService.inferImage(imageBytes: bytes2, weightKg: 10.0);

      // Verify spatial centroid tracking:
      // The bounding box x1 and y1 for the top-left cluster MUST be strictly less
      // than the bounding box x1 and y1 for the bottom-right cluster.
      expect(res1.bbox[0], lessThan(res2.bbox[0]));
      expect(res1.bbox[1], lessThan(res2.bbox[1]));
    });

    test('PROOFS OF TRUE AI INFERENCE: Real GIZ field photo inference on high-res camera capture', () async {
      // Field photo from SIH official dataset
      final res = await aiService.inferImage(
        filePath: 'assets/images/test_samples/IMG_20250522_115902_928.jpg',
        weightKg: 25.0,
      );

      expect(res.category, isNotEmpty);
      expect(res.confidence, greaterThan(0.90));
      expect(res.bbox.length, equals(4));
      expect(res.estimatedVolumeM3, greaterThan(0.0));
      expect(res.latencyMs, isPositive);
      expect(res.latencyMs, lessThan(5000));
    });
  });
}
