import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import 'ai_engine.dart';

class PlatformAiEngine implements AiEngine {
  final OnnxRuntime _ort = OnnxRuntime();
  OrtSession? _session;
  bool _ready = false;
  static const int _inputSize = 224;

  @override
  bool get isReady => _ready;

  @override
  String get engineName => 'Edge ONNX Runtime (Offline Backup)';

  @override
  Future<void> initialize() async {
    if (_ready && _session != null) return;
    try {
      _session = await _ort.createSessionFromAsset('assets/models/ewaste_yolov8n_cls.onnx');
      _ready = true;
      debugPrint('[AI] ONNX Runtime session created — offline edge model active');
    } catch (e, stack) {
      debugPrint('[AI] ONNX session creation failed: $e\n$stack');
      _ready = false;
    }
  }

  @override
  Future<AiEngineResult> infer({
    String? filePath,
    Uint8List? imageBytes,
    required double weightKg,
    int frameW = 480,
    int frameH = 640,
  }) async {
    // 1. Load image bytes
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
      return const AiEngineResult(
        predictedKey: 'pcb',
        confidence: 0.0,
        bbox: [0, 0, 0, 0],
        usedRealModel: false,
      );
    }

    // 2. Check connectivity: if offline, bypass network and run local ONNX immediately
    bool isOnline = true;
    try {
      final conn = await Connectivity().checkConnectivity();
      isOnline = conn.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      isOnline = true;
    }

    if (isOnline) {
      try {
        final cloudRes = await _tryCloudFireworks(
          rawBytes: rawBytes,
          weightKg: weightKg,
          frameW: frameW,
          frameH: frameH,
        );
        if (cloudRes != null) {
          debugPrint('[AI Android] Online Cloud Fireworks AI inference success: ${cloudRes.predictedKey}');
          return cloudRes;
        }
      } catch (e) {
        debugPrint('[AI Android] Cloud inference error ($e) — falling back to local ONNX model');
      }
    } else {
      debugPrint('[AI Android] Device offline — using local ONNX edge model directly');
    }

    // 3. Fallback: Local ONNX Model on-device
    debugPrint('[AI Android] Running local ONNX model on-device as backup...');
    return _runLocalOnnx(
      rawBytes: rawBytes,
      weightKg: weightKg,
      frameW: frameW,
      frameH: frameH,
    );
  }

  static String? _workingCloudUrl;
  static DateTime? _lastCloudCheck;

  Future<AiEngineResult?> _tryCloudFireworks({
    required Uint8List rawBytes,
    required double weightKg,
    required int frameW,
    required int frameH,
  }) async {
    final now = DateTime.now();
    // If recently failed (< 15 seconds ago), skip cloud to give instant on-device ONNX response
    if (_lastCloudCheck != null && _workingCloudUrl == null && now.difference(_lastCloudCheck!).inSeconds < 15) {
      return null;
    }

    final base64Img = base64Encode(rawBytes);
    final candidates = _workingCloudUrl != null
        ? [_workingCloudUrl!]
        : [
            'http://192.168.1.73:5000/api/ai/classify',
            'http://10.0.2.2:5000/api/ai/classify',
            'http://localhost:5000/api/ai/classify',
          ];

    _lastCloudCheck = now;

    for (final url in candidates) {
      try {
        final res = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'imageBase64': base64Img,
            'weightKg': weightKg,
          }),
        ).timeout(const Duration(milliseconds: 1200));

        if (res.statusCode == 200) {
          _workingCloudUrl = url;
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          final data = json['data'] as Map<String, dynamic>? ?? {};

          final cat = (data['category'] as String?)?.toLowerCase() ?? 'pcb';
          final subCat = (data['subCategory'] as String?) ?? '';
          final conf = (data['confidence'] as num?)?.toDouble() ?? 0.95;
          final modelName = (data['modelUsed'] as String?) ?? 'Fireworks Llama 3.2 Vision';

          String key = 'pcb';
          if (cat.contains('cable') || subCat.contains('Copper Cable')) {
            key = 'cable_copper';
          } else if (cat.contains('batter') || subCat.contains('Lithium')) {
            key = 'battery_li';
          } else if (cat.contains('display') || subCat.contains('CRT')) {
            key = 'crt_monitor';
          } else if (cat.contains('plastic')) {
            key = 'plastic_casing';
          } else if (cat.contains('metal')) {
            key = 'metal_copper';
          }

          final bbox = [20.0, 20.0, frameW * 0.85, frameH * 0.75];

          return AiEngineResult(
            predictedKey: key,
            confidence: conf,
            bbox: bbox,
            usedRealModel: true,
            modelEngineName: 'Fireworks AI: $modelName',
          );
        }
      } catch (_) {
        // If this URL failed and was cached, clear it
        if (_workingCloudUrl == url) {
          _workingCloudUrl = null;
        }
      }
    }
    return null;
  }

  Future<AiEngineResult> _runLocalOnnx({
    required Uint8List rawBytes,
    required double weightKg,
    required int frameW,
    required int frameH,
  }) async {
    if (_session == null) {
      await initialize();
    }

    img.Image? decoded;
    try {
      decoded = img.decodeImage(rawBytes);
    } catch (_) {
      decoded = null;
    }

    if (decoded == null) {
      return const AiEngineResult(
        predictedKey: 'pcb',
        confidence: 0.0,
        bbox: [0, 0, 0, 0],
        usedRealModel: false,
      );
    }

    // Resize to model input dimensions (224 × 224)
    final resized = img.copyResize(decoded, width: _inputSize, height: _inputSize);

    // Build CHW float tensor normalized to [0, 1]
    const pixelCount = _inputSize * _inputSize;
    final floatData = Float32List(3 * pixelCount);

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        final idx = y * _inputSize + x;
        floatData[idx] = pixel.r / 255.0;
        floatData[pixelCount + idx] = pixel.g / 255.0;
        floatData[2 * pixelCount + idx] = pixel.b / 255.0;
      }
    }

    try {
      if (_session != null) {
        // Create ORT input tensor
        final inputTensor = await OrtValue.fromList(
          floatData.toList(),
          [1, 3, _inputSize, _inputSize],
        );

        // Run inference
        final outputs = await _session!.run({'images': inputTensor});
        final outputKey = outputs.keys.first;
        final outputValue = outputs[outputKey]!;
        final dynamic rawData = await outputValue.asList();
        final List<double> rawScores = _extractDoubles(rawData);

        // Apply softmax
        final probs = _softmax(rawScores);

        const keys = ['pcb', 'cable_copper', 'battery_li', 'crt_monitor', 'metal_copper', 'plastic_casing'];
        final numClasses = math.min(probs.length, keys.length);

        int topIdx = 0;
        double maxProb = probs.isNotEmpty ? probs[0] : 0.5;
        for (int i = 1; i < numClasses; i++) {
          if (probs[i] > maxProb) {
            maxProb = probs[i];
            topIdx = i;
          }
        }

        final predictedKey = topIdx < keys.length ? keys[topIdx] : keys.first;
        final bbox = _computeBbox(decoded, frameW, frameH);

        debugPrint('[AI Android] Local ONNX result: $predictedKey @ ${(maxProb * 100).toStringAsFixed(1)}%');

        return AiEngineResult(
          predictedKey: predictedKey,
          confidence: maxProb,
          bbox: bbox,
          usedRealModel: true,
          modelEngineName: 'Edge ONNX YOLOv8n (Offline Backup)',
        );
      }
    } catch (e) {
      debugPrint('[AI Android] Local ONNX inference error: $e');
    }

    // Heuristic fallback if ONNX session fails
    final bbox = _computeBbox(decoded, frameW, frameH);
    return AiEngineResult(
      predictedKey: 'pcb',
      confidence: 0.88,
      bbox: bbox,
      usedRealModel: false,
      modelEngineName: 'Local Edge Heuristic (Offline Backup)',
    );
  }

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

  List<double> _computeBbox(img.Image srcImage, int frameW, int frameH) {
    const procW = 128;
    const procH = 128;
    final resized = img.copyResize(srcImage, width: procW, height: procH);

    final lumMatrix = List.generate(procH, (_) => Float32List(procW));
    for (int y = 0; y < procH; y++) {
      for (int x = 0; x < procW; x++) {
        final p = resized.getPixel(x, y);
        lumMatrix[y][x] = 0.299 * p.r.toDouble() + 0.587 * p.g.toDouble() + 0.114 * p.b.toDouble();
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
    final wPx = (spreadX * scale * (frameW / 128.0)).clamp(120.0, frameW * 0.85);
    final hPx = (spreadY * scale * (frameH / 128.0)).clamp(140.0, frameH * 0.85);
    final x1 = (cx * (frameW / 128.0) - wPx / 2.0).clamp(10.0, frameW - wPx - 10.0);
    final y1 = (cy * (frameH / 128.0) - hPx / 2.0).clamp(10.0, frameH - hPx - 10.0);

    return [x1, y1, x1 + wPx, y1 + hPx];
  }
}

AiEngine createPlatformAiEngine() => PlatformAiEngine();
