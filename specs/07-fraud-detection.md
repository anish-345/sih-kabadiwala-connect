# 07 — Fraud Detection Specification
## Kabadiwala Connect · SIH 2026 · PS 26229

---

## 1. Why Fraud Detection?

The PS explicitly asks for *"identification of abnormal or inconsistent transaction values"*.
Two fraud vectors exist in the informal e-waste chain:

| Vector | Example | Impact |
|--------|---------|--------|
| **Weight inflation** | Collector claims 5 kg, actually 1.5 kg | Recycler over-pays, collector gains |
| **Category fraud** | Declares cheap PVC cable as copper wire | 3× price difference exploited |
| **Price collusion** | Recycler sets artificially low offered rate | Collector under-earns |
| **EPR certificate fraud** | Same lot submitted twice | Double EPR credit claimed |

We address the first three with on-device checks and the fourth with server-side idempotency.

---

## 2. Fraud Signal 1 — Volume-Density Anomaly

### 2.1 Algorithm

```
Step 1 — Get bounding box from TFLite output (pixels)
         bbox = [x1, y1, x2, y2]
         w_px = x2 - x1,   h_px = y2 - y1

Step 2 — Convert to real-world dimensions
         Assume camera is held ~40 cm from subject (default).
         The camera HFOV for a typical 4 MP mobile is ~65°.
         real_width_m  = w_px / frame_width_px  × 2 × tan(HFOV/2) × 0.40
         real_height_m = h_px / frame_height_px × 2 × tan(VFOV/2) × 0.40
         depth_m       = real_width_m × 0.70          ← heuristic for depth

Step 3 — Volume estimate
         V_box = real_width_m × real_height_m × depth_m   (m³)

Step 4 — Entered weight
         W_entered (kg) from collector input

Step 5 — Inferred density
         ρ_inferred = W_entered / V_box   (kg/m³)

Step 6 — Z-score against material baseline
         μ = DENSITY_MEAN[sub_category]
         σ = DENSITY_STD[sub_category]
         Z = (ρ_inferred − μ) / σ

Step 7 — Flag if |Z| > 2.5
```

### 2.2 Density Reference Table (Dart constant map)

```dart
// lib/core/constants/density_constants.dart
const Map<String, ({double mean, double std})> kDensityParams = {
  'pcb':          (mean: 1800.0, std: 200.0),   // kg/m³
  'motherboard':  (mean: 1750.0, std: 180.0),
  'phone':        (mean: 1500.0, std: 150.0),
  'laptop':       (mean: 1200.0, std: 180.0),
  'cable_copper': (mean: 3000.0, std: 400.0),
  'cable_pvc':    (mean: 1200.0, std: 150.0),
  'battery_li':   (mean: 2000.0, std: 300.0),
  'battery_lead': (mean: 4800.0, std: 500.0),
  'crt_monitor':  (mean: 2200.0, std: 350.0),
  'lcd_panel':    (mean: 1400.0, std: 200.0),
  'motor':        (mean: 4500.0, std: 800.0),
  'plastic_pet':  (mean: 1350.0, std: 80.0),
  'plastic_hdpe': (mean:  950.0, std: 50.0),
  'plastic_pvc':  (mean: 1350.0, std: 80.0),
  'plastic_pp':   (mean:  900.0, std: 40.0),
  'metal_copper': (mean: 8940.0, std: 200.0),
  'metal_alum':   (mean: 2700.0, std: 150.0),
  'metal_steel':  (mean: 7850.0, std: 400.0),
  'glass_screen': (mean: 2500.0, std: 200.0),
  'paper_card':   (mean:  800.0, std: 100.0),
};
```

### 2.3 Dart Implementation

```dart
// lib/core/utils/density_fraud_detector.dart

import 'dart:math' as math;
import '../constants/density_constants.dart';

enum FraudSeverity { clean, warning, flag }

class DensityFraudResult {
  final double rhoInferred;   // kg/m³
  final double zScore;
  final FraudSeverity severity;
  final String? message;
  const DensityFraudResult({
    required this.rhoInferred,
    required this.zScore,
    required this.severity,
    this.message,
  });
}

class DensityFraudDetector {
  static const double _kCameraDistanceM = 0.40;
  static const double _kHFOVRad = 65.0 * math.pi / 180.0; // typical mobile
  static const double _kVFOVRad = 50.0 * math.pi / 180.0;
  static const double _kDepthRatio = 0.70;
  static const double _kWarnThreshold = 2.0;
  static const double _kFlagThreshold = 2.5;

  /// [bbox] = [x1, y1, x2, y2] in pixels
  /// [frameW], [frameH] = full frame size in pixels
  /// [weightKg] = collector-entered weight
  /// [subCategory] = inferred or selected sub-category key
  static DensityFraudResult analyse({
    required List<double> bbox,
    required int frameW,
    required int frameH,
    required double weightKg,
    required String subCategory,
  }) {
    // Guard
    if (weightKg <= 0) {
      return DensityFraudResult(
          rhoInferred: 0, zScore: 0, severity: FraudSeverity.clean);
    }

    final wPx = bbox[2] - bbox[0];
    final hPx = bbox[3] - bbox[1];
    if (wPx <= 0 || hPx <= 0) {
      return DensityFraudResult(
          rhoInferred: 0, zScore: 0, severity: FraudSeverity.clean);
    }

    final realW =
        (wPx / frameW) * 2 * math.tan(_kHFOVRad / 2) * _kCameraDistanceM;
    final realH =
        (hPx / frameH) * 2 * math.tan(_kVFOVRad / 2) * _kCameraDistanceM;
    final realD = realW * _kDepthRatio;
    final volume = realW * realH * realD;

    if (volume < 1e-6) {
      return DensityFraudResult(
          rhoInferred: 0, zScore: 0, severity: FraudSeverity.clean);
    }

    final rho = weightKg / volume;

    final params = kDensityParams[subCategory];
    if (params == null) {
      return DensityFraudResult(
          rhoInferred: rho, zScore: 0, severity: FraudSeverity.clean);
    }

    final z = (rho - params.mean) / params.std;
    final absZ = z.abs();

    final severity = absZ >= _kFlagThreshold
        ? FraudSeverity.flag
        : absZ >= _kWarnThreshold
            ? FraudSeverity.warning
            : FraudSeverity.clean;

    String? msg;
    if (severity == FraudSeverity.flag) {
      msg = z > 0
          ? 'Weight too high for visible size (Z=${ z.toStringAsFixed(1)})'
          : 'Weight too low for visible size (Z=${z.toStringAsFixed(1)})';
    } else if (severity == FraudSeverity.warning) {
      msg = 'Unusual weight-to-size ratio — please recheck';
    }

    return DensityFraudResult(
        rhoInferred: rho, zScore: z, severity: severity, message: msg);
  }
}
```

---

## 3. Fraud Signal 2 — Price Anomaly Detection

### 3.1 Algorithm (server-side, also cached locally)

```
For each new transaction quote:
  1. Fetch last 30 quotes for same sub_category + geo_region_code
  2. Compute rolling mean (μ_price) and std (σ_price)
  3. Z_price = (quoted_price − μ_price) / σ_price
  4. Flag if Z_price < −2.0 (recycler offering far below market)
     or Z_price > +3.0 (suspiciously high, possible data entry error)
```

### 3.2 Dart Implementation (local cache version)

```dart
// lib/core/utils/price_anomaly_detector.dart

class PriceAnomalyResult {
  final double zScore;
  final bool isAnomaly;
  final String? message;
  const PriceAnomalyResult(
      {required this.zScore, required this.isAnomaly, this.message});
}

class PriceAnomalyDetector {
  static const double _kLowZThreshold = -2.0;
  static const double _kHighZThreshold = 3.0;

  static PriceAnomalyResult analyse({
    required double quotedPrice,
    required List<double> recentPrices, // last 30 quotes, same category+region
  }) {
    if (recentPrices.length < 5) {
      return PriceAnomalyResult(zScore: 0, isAnomaly: false);
    }

    final mean = recentPrices.reduce((a, b) => a + b) / recentPrices.length;
    final variance = recentPrices
            .map((p) => (p - mean) * (p - mean))
            .reduce((a, b) => a + b) /
        recentPrices.length;
    final std = math.sqrt(variance);

    if (std < 1e-3) {
      return PriceAnomalyResult(zScore: 0, isAnomaly: false);
    }

    final z = (quotedPrice - mean) / std;
    final isAnomaly = z < _kLowZThreshold || z > _kHighZThreshold;

    String? msg;
    if (z < _kLowZThreshold) {
      msg = 'Offered price is ₹${(mean - quotedPrice).toStringAsFixed(0)}'
          ' below market average — consider another recycler';
    } else if (z > _kHighZThreshold) {
      msg = 'Unusually high offer — verify before accepting';
    }

    return PriceAnomalyResult(zScore: z, isAnomaly: isAnomaly, message: msg);
  }
}
```

---

## 4. Fraud Signal 3 — Duplicate Lot / Replay Attack

```dart
// lib/core/utils/duplicate_detector.dart

class DuplicateDetector {
  /// Returns true if this imageHash has been seen in the last 30 days
  static Future<bool> isDuplicate({
    required String imageEdgeHash,
    required MaterialRepository repo,
  }) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final existing = await repo.findByImageHash(imageEdgeHash, since: cutoff);
    return existing != null;
  }
}
```

Server-side: idempotency key on `/api/v1/sync` prevents double-submission (see spec 06).

---

## 5. UI Alert Flow

```
FraudSeverity.clean   → No UI indicator, proceed normally
FraudSeverity.warning → Yellow banner: "असामान्य वजन — कृपया जाँच करें"
                         Collector can proceed after acknowledging
FraudSeverity.flag    → Orange dialog: reason + "क्या आप जारी रखना चाहते हैं?"
                         Requires tap confirmation to proceed
                         is_fraud_flagged = true written to DB
                         Flagged for backend review queue
```

### Severity badges in Hindi/Marathi

| Severity | Hindi | Marathi | Colour |
|----------|-------|---------|--------|
| clean | — | — | — |
| warning | असामान्य वजन | असामान्य वजन | `#FF9800` |
| flag | संदिग्ध लेनदेन | संशयास्पद व्यवहार | `#F44336` |

---

## 6. Backend Review Queue (Server Logic Sketch)

```
POST /api/v1/sync  →  SyncWorker uploads flagged lot
                       is_fraud_flagged = true in payload

Backend:
  IF is_fraud_flagged THEN
    INSERT INTO fraud_review_queue (lot_id, z_score, flagged_at)
    SET transactions_ledger.tx_lifecycle_state = 'under_review'

Admin panel:
  GET /api/v1/admin/fraud-queue
  Admin reviews, approves or rejects
  PUT /api/v1/admin/fraud-queue/{lot_id}/approve  → normal flow resumes
  PUT /api/v1/admin/fraud-queue/{lot_id}/reject   → lot voided
```

---

## 7. AI/ML Training Loop

Every inference event writes to `aiml_training_telemetry`:

```
sample_id          UUIDv4
source_lot_id      → materials_registry.lot_id
bounding_box_json  [x1,y1,x2,y2] normalised 0-1
inferred_class     model prediction
ground_truth_class null until human review / recycler confirms
model_confidence   0.0–1.0
density_z_score    calculated value
is_fraud_flagged   boolean
device_info        "<model>_API<sdk>"
created_at         epoch ms
```

Low-confidence (< 0.5) + fraud-flagged samples are prioritised for human labelling during model retraining cycles.

---

## 8. Testing

```dart
// test/unit/density_fraud_test.dart

void main() {
  group('DensityFraudDetector', () {
    test('clean signal for typical PCB', () {
      // PCB: ~18 cm × 12 cm × 2 cm → V ≈ 0.000432 m³, weight 0.78 kg → ρ ≈ 1806
      final r = DensityFraudDetector.analyse(
        bbox: [100, 100, 460, 340],   // 360×240 px in 2000×1500 frame
        frameW: 2000, frameH: 1500,
        weightKg: 0.78,
        subCategory: 'pcb',
      );
      expect(r.severity, FraudSeverity.clean);
    });

    test('flags when weight 10× too high', () {
      final r = DensityFraudDetector.analyse(
        bbox: [100, 100, 460, 340],
        frameW: 2000, frameH: 1500,
        weightKg: 7.8,               // 10× inflation
        subCategory: 'pcb',
      );
      expect(r.severity, FraudSeverity.flag);
      expect(r.zScore, greaterThan(2.5));
    });

    test('warns at 2.0 < Z < 2.5', () {
      final r = DensityFraudDetector.analyse(
        bbox: [100, 100, 460, 340],
        frameW: 2000, frameH: 1500,
        weightKg: 1.8,
        subCategory: 'pcb',
      );
      expect(r.severity, FraudSeverity.warning);
    });
  });
}
```

---

**Status:** ✅ Ready for implementation  
**Implements:** PS 26229 requirement — *"identification of abnormal or inconsistent transaction values"*
