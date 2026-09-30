import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/density_fraud_detector.dart';
import 'ai_engine.dart';
import 'ai_engine_platform.dart';

// ── Data Models ───────────────────────────────────────────────────────────────

class AiModelMeta {
  final String modelName;
  final String architecture;
  final List<int> inputResolution;
  final String targetPlatform;
  final Map<String, dynamic> benchmarkedLatencyMs;

  AiModelMeta({
    required this.modelName,
    required this.architecture,
    required this.inputResolution,
    required this.targetPlatform,
    required this.benchmarkedLatencyMs,
  });

  factory AiModelMeta.fromJson(Map<String, dynamic> json) {
    return AiModelMeta(
      modelName: json['modelName'] as String? ?? 'YOLOv8n-Ewaste-Edge',
      architecture: json['architecture'] as String? ?? 'YOLOv8n INT8 / Fireworks Vision',
      inputResolution: (json['inputResolution'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [224, 224, 3],
      targetPlatform: json['targetPlatform'] as String? ?? 'Edge / Cloud',
      benchmarkedLatencyMs:
          (json['benchmarkedLatencyMs'] as Map<String, dynamic>?) ?? {},
    );
  }
}

class AiCategoryLabel {
  final int id;
  final String key;
  final String name;
  final String hindi;
  final String marathi;
  final String defaultSubCategory;
  final String category;
  final String hazard;

  AiCategoryLabel({
    required this.id,
    required this.key,
    required this.name,
    required this.hindi,
    required this.marathi,
    required this.defaultSubCategory,
    required this.category,
    required this.hazard,
  });

  factory AiCategoryLabel.fromJson(Map<String, dynamic> json) {
    return AiCategoryLabel(
      id: json['id'] as int? ?? 0,
      key: json['key'] as String? ?? 'pcb',
      name: json['name'] as String? ?? 'PCB',
      hindi: json['hindi'] as String? ?? 'प्रिंटेड सर्किट बोर्ड',
      marathi: json['marathi'] as String? ?? 'सर्किट बोर्ड',
      defaultSubCategory: json['defaultSubCategory'] as String? ??
          'Mid Grade (Motherboards / GPUs)',
      category: json['category'] as String? ?? 'PCB',
      hazard: json['hazard'] as String? ?? 'None',
    );
  }
}

class AiDetectionResult {
  final String category;
  final String subCategory;
  final String hindiName;
  final String marathiName;
  final double confidence;
  final List<double> bbox;
  final int latencyMs;
  final String hazardLevel;
  final String hazardDescription;
  final double estimatedVolumeM3;
  final DensityFraudResult fraudResult;
  final bool usedRealModel;
  final String? modelEngineName;

  const AiDetectionResult({
    required this.category,
    required this.subCategory,
    required this.hindiName,
    required this.marathiName,
    required this.confidence,
    required this.bbox,
    required this.latencyMs,
    required this.hazardLevel,
    required this.hazardDescription,
    required this.estimatedVolumeM3,
    required this.fraudResult,
    this.usedRealModel = true,
    this.modelEngineName,
  });
}

// ── Inference Service ─────────────────────────────────────────────────────────

class AiInferenceService {
  AiModelMeta? _meta;
  List<AiCategoryLabel> _labels = [];
  bool _initialized = false;

  final AiEngine _engine = createPlatformAiEngine();

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      // Load metadata
      final metaStr =
          await rootBundle.loadString('assets/models/model_metadata.json');
      _meta =
          AiModelMeta.fromJson(jsonDecode(metaStr) as Map<String, dynamic>);

      // Load labels
      final labelStr =
          await rootBundle.loadString('assets/models/labels.json');
      final labelJson = jsonDecode(labelStr) as Map<String, dynamic>;
      final list = labelJson['classes'] as List<dynamic>? ?? [];
      _labels = list
          .map((e) => AiCategoryLabel.fromJson(e as Map<String, dynamic>))
          .toList();

      await _engine.initialize();
      _initialized = true;
    } catch (e) {
      debugPrint('[AI] Initialization fallback: $e');
      _labels = _getBaselineLabels();
      _initialized = true;
    }
  }

  List<AiCategoryLabel> get labels => _labels;
  AiModelMeta? get metadata => _meta;
  bool get isOnnxActive => _engine.isReady;
  String get engineName => _engine.engineName;

  /// Run inference on an image — uses real model (ONNX on Android, Fireworks on Web)
  Future<AiDetectionResult> inferImage({
    String? filePath,
    Uint8List? imageBytes,
    required double weightKg,
    int frameW = 480,
    int frameH = 640,
  }) async {
    await initialize();

    final stopwatch = Stopwatch()..start();

    final outcome = await _engine.infer(
      filePath: filePath,
      imageBytes: imageBytes,
      weightKg: weightKg,
      frameW: frameW,
      frameH: frameH,
    );

    final matchedLabel = _labels.firstWhere(
      (l) => l.key == outcome.predictedKey,
      orElse: () => _labels.first,
    );

    // Calculate 3D volume from bounding box
    final wPx = (outcome.bbox.length == 4) ? (outcome.bbox[2] - outcome.bbox[0]) : 200.0;
    final hPx = (outcome.bbox.length == 4) ? (outcome.bbox[3] - outcome.bbox[1]) : 200.0;
    final realW = (wPx / frameW) * 2 * math.tan(65.0 * math.pi / 360.0) * 0.40;
    final realH = (hPx / frameH) * 2 * math.tan(50.0 * math.pi / 360.0) * 0.40;
    final realD = realW * 0.70;
    final volumeM3 = math.max(0.0001, realW * realH * realD);

    // Density fraud detection
    final fraudRes = DensityFraudDetector.analyse(
      bbox: outcome.bbox,
      frameW: frameW,
      frameH: frameH,
      weightKg: weightKg,
      subCategory: outcome.predictedKey,
    );

    stopwatch.stop();
    final latency = math.max(1, stopwatch.elapsedMilliseconds);

    return AiDetectionResult(
      category: matchedLabel.category,
      subCategory: matchedLabel.defaultSubCategory,
      hindiName: matchedLabel.hindi,
      marathiName: matchedLabel.marathi,
      confidence: outcome.confidence,
      bbox: outcome.bbox,
      latencyMs: latency,
      hazardLevel: _getHazardLevel(matchedLabel.hazard),
      hazardDescription: matchedLabel.hazard,
      estimatedVolumeM3: volumeM3,
      fraudResult: fraudRes,
      usedRealModel: outcome.usedRealModel,
      modelEngineName: outcome.modelEngineName ?? _engine.engineName,
    );
  }

  String _getHazardLevel(String hazard) {
    if (hazard.toLowerCase().contains('high')) return 'HIGH';
    if (hazard.toLowerCase().contains('medium')) return 'MEDIUM';
    if (hazard.toLowerCase().contains('low')) return 'LOW';
    return 'SAFE';
  }

  List<AiCategoryLabel> _getBaselineLabels() => [
        AiCategoryLabel(
          id: 0, key: 'pcb',
          name: 'Printed Circuit Boards (PCB)',
          hindi: 'प्रिंटेड सर्किट बोर्ड', marathi: 'सर्किट बोर्ड',
          defaultSubCategory: 'Mid Grade (Motherboards / GPUs)',
          category: 'PCB', hazard: 'Low - Lead Solder',
        ),
        AiCategoryLabel(
          id: 1, key: 'cable_copper',
          name: 'Insulated Copper Cables',
          hindi: 'तांबे के तार व केबल', marathi: 'तांब्याची वायर',
          defaultSubCategory: 'Heavy Copper Cables (Insulated)',
          category: 'Cables', hazard: 'None',
        ),
        AiCategoryLabel(
          id: 2, key: 'battery_li',
          name: 'Lithium-Ion & Lead Batteries',
          hindi: 'लिथियम-आयन / लेड बैटरी', marathi: 'लिथियम बॅटरी',
          defaultSubCategory: 'Lithium-Ion Cells (Laptop / EV / Mobile)',
          category: 'Batteries', hazard: 'High - Fire & Acid Hazard',
        ),
        AiCategoryLabel(
          id: 3, key: 'crt_monitor',
          name: 'CRT Funnel Glass & Display',
          hindi: 'सीआरटी मॉनिटर व डिस्प्ले ग्लास', marathi: 'सीआरटी काच',
          defaultSubCategory: 'CRT Funnel Glass / Monitors',
          category: 'Displays', hazard: 'Medium - Lead Impregnated',
        ),
        AiCategoryLabel(
          id: 4, key: 'metal_copper',
          name: 'Copper & Brass Scrap',
          hindi: 'तांबा व पीतल स्क्रैप', marathi: 'तांबे व पितळ',
          defaultSubCategory: 'Heavy Copper Cables (Insulated)',
          category: 'Cables', hazard: 'None',
        ),
        AiCategoryLabel(
          id: 5, key: 'plastic_casing',
          name: 'ABS / PVC E-Waste Casing',
          hindi: 'ई-कचरा प्लास्टिक आवरण', marathi: 'प्लॅस्टिक कव्हर',
          defaultSubCategory: 'Flame-Retardant E-Plastics (ABS/HIPS)',
          category: 'Plastics', hazard: 'Toxic - Brominated Flame Retardants (BFR)',
        ),
      ];
}

final aiInferenceServiceProvider = Provider<AiInferenceService>((ref) {
  return AiInferenceService();
});
