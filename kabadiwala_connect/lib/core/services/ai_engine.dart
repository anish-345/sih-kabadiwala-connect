import 'package:flutter/foundation.dart';

class AiEngineResult {
  final String predictedKey;
  final double confidence;
  final List<double> bbox;
  final bool usedRealModel;
  final String? modelEngineName;

  const AiEngineResult({
    required this.predictedKey,
    required this.confidence,
    required this.bbox,
    required this.usedRealModel,
    this.modelEngineName,
  });
}

abstract class AiEngine {
  Future<void> initialize();
  bool get isReady;
  String get engineName;
  Future<AiEngineResult> infer({
    String? filePath,
    Uint8List? imageBytes,
    required double weightKg,
    int frameW = 480,
    int frameH = 640,
  });
}
