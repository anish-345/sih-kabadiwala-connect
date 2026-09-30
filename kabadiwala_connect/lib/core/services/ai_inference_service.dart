import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../utils/density_fraud_detector.dart';

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
      architecture: json['architecture'] as String? ?? 'YOLOv8n INT8',
      inputResolution: (json['inputResolution'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [224, 224, 3],
      targetPlatform: json['targetPlatform'] as String? ?? 'Android NNAPI',
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
    this.usedRealModel = false,
  });
}

// ── Inference Service ─────────────────────────────────────────────────────────

class AiInferenceService {
  AiModelMeta? _meta;
  List<AiCategoryLabel> _labels = [];
  bool _initialized = false;

  // ONNX Runtime components
  final OnnxRuntime _ort = OnnxRuntime();
  OrtSession? _session;
  bool _onnxReady = false;

  static const int _inputSize = 224;

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

      // Load ONNX model into real inference session
      try {
        _session = await _ort
            .createSessionFromAsset('assets/models/ewaste_yolov8n_cls.onnx');
        _onnxReady = true;
        debugPrint(
            '[AI] ONNX Runtime session created — offline edge model active');
      } catch (e, stack) {
        debugPrint('[AI] ONNX session creation failed: $e\n$stack');
        _onnxReady = false;
      }

      _initialized = true;
    } catch (e) {
      debugPrint('[AI] Initialization error: $e');
      _labels = _getBaselineLabels();
      _initialized = true;
    }
  }

  List<AiCategoryLabel> get labels => _labels;
  AiModelMeta? get metadata => _meta;
  bool get isOnnxActive => _onnxReady;

  /// Run inference on an image — uses real ONNX model when available
  Future<AiDetectionResult> inferImage({
    String? filePath,
    Uint8List? imageBytes,
    required double weightKg,
    int frameW = 480,
    int frameH = 640,
  }) async {
    await initialize();

    final stopwatch = Stopwatch()..start();

    // 1. Load raw bytes
    Uint8List rawBytes = Uint8List(0);
    if (imageBytes != null && imageBytes.isNotEmpty) {
      rawBytes = imageBytes;
    } else if (filePath != null && filePath.isNotEmpty) {
      try {
        if (filePath.startsWith('assets/')) {
          final bd = await rootBundle.load(filePath);
          rawBytes = bd.buffer.asUint8List();
        } else {
          rawBytes = await File(filePath).readAsBytes();
        }
      } catch (_) {
        try {
          rawBytes = await File(filePath).readAsBytes();
        } catch (_) {
          rawBytes = Uint8List(0);
        }
      }
    }

    if (rawBytes.isEmpty) {
      stopwatch.stop();
      return _buildEmptyResult(stopwatch.elapsedMilliseconds, weightKg,
          frameW, frameH);
    }

    // 2. Decode image
    img.Image? decoded;
    try {
      decoded = img.decodeImage(rawBytes);
    } catch (_) {
      decoded = null;
    }

    if (decoded == null) {
      stopwatch.stop();
      return _buildEmptyResult(stopwatch.elapsedMilliseconds, weightKg,
          frameW, frameH);
    }

    // 3. Run real ONNX inference (Model itself is the offline inference, no heuristic fallback)
    final outcome = await _runOnnxInference(decoded, frameW, frameH);

    final matchedLabel = _labels.firstWhere(
      (l) => l.key == outcome.predictedKey,
      orElse: () => _labels.first,
    );

    // 4. Calculate 3D volume from bounding box
    final wPx = outcome.bbox[2] - outcome.bbox[0];
    final hPx = outcome.bbox[3] - outcome.bbox[1];
    final realW =
        (wPx / frameW) * 2 * math.tan(65.0 * math.pi / 360.0) * 0.40;
    final realH =
        (hPx / frameH) * 2 * math.tan(50.0 * math.pi / 360.0) * 0.40;
    final realD = realW * 0.70;
    final volumeM3 = math.max(0.0001, realW * realH * realD);

    // 5. Density fraud detection
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
      usedRealModel: true,
    );
  }

  // ── Real ONNX Inference (Offline Edge Engine) ──────────────────────────────

  Future<_InferenceOutcome> _runOnnxInference(
    img.Image srcImage,
    int frameW,
    int frameH,
  ) async {
    if (_session == null) {
      _session = await _ort
          .createSessionFromAsset('assets/models/ewaste_yolov8n_cls.onnx');
      _onnxReady = true;
    }

    // Resize to model input dimensions (224 × 224)
    final resized =
        img.copyResize(srcImage, width: _inputSize, height: _inputSize);

    // Build CHW float tensor normalized to [0, 1]
    // YOLOv8-cls expects NCHW format: [1, 3, 224, 224]
    const pixelCount = _inputSize * _inputSize;
    final floatData = Float32List(3 * pixelCount);

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        final idx = y * _inputSize + x;
        floatData[idx] = pixel.r / 255.0; // R channel
        floatData[pixelCount + idx] = pixel.g / 255.0; // G channel
        floatData[2 * pixelCount + idx] = pixel.b / 255.0; // B channel
      }
    }

    // Create ORT input tensor
    final inputTensor = await OrtValue.fromList(
      floatData.toList(),
      [1, 3, _inputSize, _inputSize],
    );

    // Run inference
    final outputs = await _session!.run({'images': inputTensor});

    // Parse output — YOLOv8-cls outputs shape [1, numClasses]
    final outputKey = outputs.keys.first;
    final outputValue = outputs[outputKey]!;
    final dynamic rawData = await outputValue.asList();

    // Universal numeric extractor: Handles any nested structure (Float32List, List<Float32List>, etc.)
    final List<double> rawScores = _extractDoubles(rawData);

    // Apply softmax
    final probs = _softmax(rawScores);

    // Map model output indices to our label keys
    final numClasses = math.min(probs.length, _labels.length);

    int topIdx = 0;
    double maxProb = probs.isNotEmpty ? probs[0] : 0.5;
    for (int i = 1; i < numClasses; i++) {
      if (probs[i] > maxProb) {
        maxProb = probs[i];
        topIdx = i;
      }
    }

    final predictedLabel =
        topIdx < _labels.length ? _labels[topIdx] : _labels.first;

    // Generate bbox via gradient energy localization on the real image
    final bbox = _computeBbox(srcImage, frameW, frameH, predictedLabel.key);

    debugPrint(
        '[AI] ONNX result: ${predictedLabel.key} @ ${(maxProb * 100).toStringAsFixed(1)}%');

    return _InferenceOutcome(
      predictedKey: predictedLabel.key,
      confidence: maxProb,
      bbox: bbox,
    );
  }

  /// Recursively extracts all double/numeric values from any nested tensor structure
  List<double> _extractDoubles(dynamic obj) {
    final List<double> result = [];
    void extract(dynamic item) {
      if (item == null) return;
      if (item is num) {
        result.add(item.toDouble());
      } else if (item is Float32List) {
        for (int i = 0; i < item.length; i++) {
          result.add(item[i].toDouble());
        }
      } else if (item is Float64List) {
        for (int i = 0; i < item.length; i++) {
          result.add(item[i]);
        }
      } else if (item is Iterable) {
        for (final sub in item) {
          extract(sub);
        }
      }
    }
    extract(obj);
    return result;
  }

  // ── Shared Utilities ───────────────────────────────────────────────────────

  List<double> _softmax(List<double> logits) {
    if (logits.isEmpty) return [];
    final maxLogit = logits.reduce(math.max);
    final expLogits = logits.map((z) {
      final diff = z - maxLogit;
      return (diff.isNaN || diff.isInfinite) ? 1.0 : math.exp(diff);
    }).toList();
    final sumExp = expLogits.reduce((a, b) => a + b);
    if (sumExp == 0 || sumExp.isNaN) {
      return List.filled(logits.length, 1.0 / logits.length);
    }
    return expLogits.map((e) => e / sumExp).toList();
  }

  List<double> _computeBbox(
    img.Image srcImage,
    int frameW,
    int frameH,
    String categoryKey,
  ) {
    // Compute gradient energy centroid for localization
    const procW = 128;
    const procH = 128;
    final resized = img.copyResize(srcImage, width: procW, height: procH);

    final lumMatrix = List.generate(procH, (_) => Float32List(procW));
    for (int y = 0; y < procH; y++) {
      for (int x = 0; x < procW; x++) {
        final p = resized.getPixel(x, y);
        lumMatrix[y][x] =
            0.299 * p.r.toDouble() + 0.587 * p.g.toDouble() +
                0.114 * p.b.toDouble();
      }
    }

    double totalEnergy = 0.0;
    double weightedX = 0.0;
    double weightedY = 0.0;

    for (int y = 1; y < procH - 1; y++) {
      for (int x = 1; x < procW - 1; x++) {
        final gx = (lumMatrix[y][x + 1] - lumMatrix[y][x - 1]).abs();
        final gy = (lumMatrix[y + 1][x] - lumMatrix[y - 1][x]).abs();
        final energy = gx + gy;
        if (energy > 10.0) {
          totalEnergy += energy;
          weightedX += x * energy;
          weightedY += y * energy;
        }
      }
    }

    final cx = totalEnergy > 0 ? (weightedX / totalEnergy) : 64.0;
    final cy = totalEnergy > 0 ? (weightedY / totalEnergy) : 64.0;

    double spreadX = 25.0;
    double spreadY = 25.0;
    if (totalEnergy > 0) {
      double sX = 0, sY = 0;
      for (int y = 1; y < procH - 1; y++) {
        for (int x = 1; x < procW - 1; x++) {
          final gx = (lumMatrix[y][x + 1] - lumMatrix[y][x - 1]).abs();
          final gy = (lumMatrix[y + 1][x] - lumMatrix[y - 1][x]).abs();
          final energy = gx + gy;
          if (energy > 10.0) {
            sX += (x - cx) * (x - cx) * energy;
            sY += (y - cy) * (y - cy) * energy;
          }
        }
      }
      spreadX = math.sqrt(sX / totalEnergy);
      spreadY = math.sqrt(sY / totalEnergy);
    }

    const scale = 3.0;
    final wPx = (spreadX * scale * (frameW / 128.0))
        .clamp(120.0, frameW * 0.85);
    final hPx = (spreadY * scale * (frameH / 128.0))
        .clamp(140.0, frameH * 0.85);

    final x1 = (cx * (frameW / 128.0) - wPx / 2.0)
        .clamp(10.0, frameW - wPx - 10.0);
    final y1 = (cy * (frameH / 128.0) - hPx / 2.0)
        .clamp(10.0, frameH - hPx - 10.0);

    return [x1, y1, x1 + wPx, y1 + hPx];
  }

  AiDetectionResult _buildEmptyResult(
    int elapsedMs,
    double weightKg,
    int frameW,
    int frameH,
  ) {
    final label = _labels.isNotEmpty ? _labels.first : _getBaselineLabels().first;
    return AiDetectionResult(
      category: label.category,
      subCategory: label.defaultSubCategory,
      hindiName: label.hindi,
      marathiName: label.marathi,
      confidence: 0.0, // Honest: no image = no confidence
      bbox: [0, 0, 0, 0],
      latencyMs: math.max(1, elapsedMs),
      hazardLevel: 'SAFE',
      hazardDescription: 'No image provided',
      estimatedVolumeM3: 0.0,
      fraudResult: const DensityFraudResult(
        rhoInferred: 0,
        zScore: 0,
        severity: FraudSeverity.clean,
      ),
      usedRealModel: false,
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

  void dispose() {
    _session?.close();
  }
}

class _InferenceOutcome {
  final String predictedKey;
  final double confidence;
  final List<double> bbox;

  _InferenceOutcome({
    required this.predictedKey,
    required this.confidence,
    required this.bbox,
  });
}

final aiInferenceServiceProvider = Provider<AiInferenceService>((ref) {
  return AiInferenceService();
});
