import 'dart:math' as math;

// ── Density reference data (spec 07) ─────────────────────────────────────────
const _kDensity = <String, ({double mean, double std})>{
  'pcb':           (mean: 1800.0, std: 200.0),
  'motherboard':   (mean: 1750.0, std: 180.0),
  'phone':         (mean: 1500.0, std: 150.0),
  'laptop':        (mean: 1200.0, std: 180.0),
  'cable_copper':  (mean: 3000.0, std: 400.0),
  'cable_pvc':     (mean: 1200.0, std: 150.0),
  'battery_li':    (mean: 2000.0, std: 300.0),
  'battery_lead':  (mean: 4800.0, std: 500.0),
  'crt_monitor':   (mean: 2200.0, std: 350.0),
  'lcd_panel':     (mean: 1400.0, std: 200.0),
  'motor':         (mean: 4500.0, std: 800.0),
  'plastic_pet':   (mean: 1350.0, std:  80.0),
  'plastic_hdpe':  (mean:  950.0, std:  50.0),
  'plastic_pvc':   (mean: 1350.0, std:  80.0),
  'plastic_pp':    (mean:  900.0, std:  40.0),
  'metal_copper':  (mean: 8940.0, std: 200.0),
  'metal_alum':    (mean: 2700.0, std: 150.0),
  'metal_steel':   (mean: 7850.0, std: 400.0),
  'glass_screen':  (mean: 2500.0, std: 200.0),
  'paper_card':    (mean:  800.0, std: 100.0),
};

enum FraudSeverity { clean, warning, flag }

class DensityFraudResult {
  const DensityFraudResult({
    required this.rhoInferred,
    required this.zScore,
    required this.severity,
    this.message,
  });

  final double rhoInferred;
  final double zScore;
  final FraudSeverity severity;
  final String? message;
}

class DensityFraudDetector {
  static const _kDist    = 0.40; // camera-to-subject distance in metres
  static const _kHFOV    = 65.0 * math.pi / 180.0;
  static const _kVFOV    = 50.0 * math.pi / 180.0;
  static const _kDepthR  = 0.70; // depth ≈ 70% of width
  static const _kWarn    = 2.0;
  static const _kFlag    = 2.5;

  /// bbox = [x1, y1, x2, y2] in pixels
  static DensityFraudResult analyse({
    required List<double> bbox,
    required int frameW,
    required int frameH,
    required double weightKg,
    required String subCategory,
  }) {
    if (weightKg <= 0) {
      return const DensityFraudResult(rhoInferred: 0, zScore: 0, severity: FraudSeverity.clean);
    }

    final wPx = bbox[2] - bbox[0];
    final hPx = bbox[3] - bbox[1];
    if (wPx <= 0 || hPx <= 0) {
      return const DensityFraudResult(rhoInferred: 0, zScore: 0, severity: FraudSeverity.clean);
    }

    final realW = (wPx / frameW) * 2 * math.tan(_kHFOV / 2) * _kDist;
    final realH = (hPx / frameH) * 2 * math.tan(_kVFOV / 2) * _kDist;
    final vol   = realW * realH * (realW * _kDepthR);

    if (vol < 1e-6) {
      return const DensityFraudResult(rhoInferred: 0, zScore: 0, severity: FraudSeverity.clean);
    }

    final rho    = weightKg / vol;
    final params = _kDensity[subCategory];
    if (params == null) {
      return DensityFraudResult(rhoInferred: rho, zScore: 0, severity: FraudSeverity.clean);
    }

    final z    = (rho - params.mean) / params.std;
    final absZ = z.abs();

    final severity = absZ >= _kFlag
        ? FraudSeverity.flag
        : absZ >= _kWarn
            ? FraudSeverity.warning
            : FraudSeverity.clean;

    String? msg;
    if (severity == FraudSeverity.flag) {
      msg = z > 0
          ? 'Weight too high for visible size (Z=${z.toStringAsFixed(1)})'
          : 'Weight too low for visible size (Z=${z.toStringAsFixed(1)})';
    } else if (severity == FraudSeverity.warning) {
      msg = 'Unusual weight-to-size ratio — please recheck';
    }

    return DensityFraudResult(rhoInferred: rho, zScore: z, severity: severity, message: msg);
  }
}
