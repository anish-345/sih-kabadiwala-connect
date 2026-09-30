import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/providers/app_state.dart';
import '../../../../core/services/ai_inference_service.dart';
import '../../../../core/storage/database.dart';
import '../../../../core/storage/models.dart';
import '../../../../core/utils/density_fraud_detector.dart';
import '../../../../core/widgets/app_surface.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _weightController = TextEditingController(text: '20.0');
  final _picker = ImagePicker();

  String? _capturedImagePath;
  String? _benchmarkAssetPath;
  String _selectedCategory = 'PCB';
  String _selectedSubCategory = 'Mid Grade (Motherboards / GPUs)';
  String _conditionGrade = 'Grade A (Intact)';
  DensityFraudResult? _fraudResult;
  AiDetectionResult? _aiResult;
  bool _isAnalyzing = false;

  List<({
    String Function(String) getName,
    String cat,
    String subCat,
    double defaultKg,
    IconData icon,
    String assetImg,
  })> _getScrapPresets() => [
        (
          getName: (lang) => switch (lang) {
                'mr' => 'मदरबोर्ड',
                'en' => 'Motherboard',
                _ => 'मदरबोर्ड',
              },
          cat: 'PCB',
          subCat: 'Mid Grade (Motherboards / GPUs)',
          defaultKg: 20.0,
          icon: Icons.developer_board,
          assetImg: 'assets/images/benchmark/motherboard_sample.jpg',
        ),
        (
          getName: (lang) => switch (lang) {
                'mr' => 'तांबे केबल',
                'en' => 'Copper Cable',
                _ => 'तांबा केबल',
              },
          cat: 'Cables',
          subCat: 'Heavy Copper Cables (Insulated)',
          defaultKg: 10.0,
          icon: Icons.cable,
          assetImg: 'assets/images/benchmark/copper_cable_sample.jpg',
        ),
        (
          getName: (lang) => switch (lang) {
                'mr' => 'लिथियम बॅटरी',
                'en' => 'Li-Ion Battery',
                _ => 'लिथियम बैटरी',
              },
          cat: 'Batteries',
          subCat: 'Lithium-Ion Cells (Laptop / EV / Mobile)',
          defaultKg: 5.0,
          icon: Icons.battery_alert,
          assetImg: 'assets/images/benchmark/battery_li_sample.jpg',
        ),
        (
          getName: (lang) => switch (lang) {
                'mr' => 'सीआरटी काच',
                'en' => 'CRT Glass',
                _ => 'सीआरटी ग्लास',
              },
          cat: 'Displays',
          subCat: 'CRT Funnel Glass / Monitors',
          defaultKg: 15.0,
          icon: Icons.tv,
          assetImg: 'assets/images/benchmark/crt_glass_sample.jpg',
        ),
      ];

  final List<({String name, String assetImg})> _gizFieldSamples = [
    (
      name: 'GIZ Field #1',
      assetImg: 'assets/images/test_samples/IMG_20250522_115902_928.jpg',
    ),
    (
      name: 'GIZ Field #2',
      assetImg: 'assets/images/test_samples/IMG_20250522_115909_024.jpg',
    ),
    (
      name: 'GIZ Field #3',
      assetImg: 'assets/images/test_samples/IMG_20250522_121901_241.jpg',
    ),
    (
      name: 'GIZ Field #4',
      assetImg: 'assets/images/test_samples/IMG_20250522_125712_264.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectBenchmarkSample(
        'assets/images/benchmark/motherboard_sample.jpg',
        'Mid Grade (Motherboards / GPUs)',
        20.0,
      );
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
          source: source, maxWidth: 1024, maxHeight: 1024);
      if (picked != null) {
        setState(() {
          _capturedImagePath = picked.path;
          _benchmarkAssetPath = null;
        });
        await _runAiInference(filePath: picked.path);
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  Future<void> _selectBenchmarkSample(
      String assetPath, String defaultSubCat, double defaultKg) async {
    setState(() {
      _benchmarkAssetPath = assetPath;
      _capturedImagePath = null;
      _weightController.text = defaultKg.toString();
    });
    await _runAiInference(filePath: assetPath);
  }

  Future<void> _runAiInference({String? filePath}) async {
    setState(() => _isAnalyzing = true);
    final weight = double.tryParse(_weightController.text) ?? 20.0;

    final aiService = ref.read(aiInferenceServiceProvider);
    final result = await aiService.inferImage(
      filePath: filePath ?? _capturedImagePath ?? _benchmarkAssetPath,
      weightKg: weight,
    );

    final db = ref.read(databaseProvider);
    final allPrices = db.getAllPrices();
    String safeSubCategory = result.subCategory;
    String safeCategory = result.category;
    if (allPrices.isNotEmpty && !allPrices.any((p) => p.subCategory == safeSubCategory)) {
      final match = allPrices.firstWhere(
        (p) => p.category.toLowerCase() == safeCategory.toLowerCase(),
        orElse: () => allPrices.first,
      );
      safeSubCategory = match.subCategory;
      safeCategory = match.category;
    }

    setState(() {
      _aiResult = result;
      _selectedCategory = safeCategory;
      _selectedSubCategory = safeSubCategory;
      _fraudResult = result.fraudResult;
      _isAnalyzing = false;
    });
  }

  void _recalcDensityFraud() {
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    if (weight <= 0) return;

    final subCatKey = switch (_selectedCategory) {
      'PCB' => 'motherboard',
      'Cables' => 'cable_copper',
      'Batteries' => 'battery_li',
      'Displays' => 'crt_monitor',
      _ => 'pcb',
    };

    final res = DensityFraudDetector.analyse(
      bbox: _aiResult?.bbox ?? [40.0, 60.0, 400.0, 480.0],
      frameW: 480,
      frameH: 640,
      weightKg: weight,
      subCategory: subCatKey,
    );

    setState(() => _fraudResult = res);
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final user = ref.watch(appStateProvider);
    final lang = user.language;

    final allPrices = db.getAllPrices();
    final currentPrice = db.getPriceBySubCategory(_selectedSubCategory) ??
        (allPrices.isNotEmpty ? allPrices.first : null);

    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final ratePerKg = currentPrice?.netOfferedPrice ?? 0.0;
    final informalRate = currentPrice?.informalBaseRate ?? 0.0;
    final totalValuation = weight * ratePerKg;
    final collectorSurplus = weight * (ratePerKg - informalRate);
    final presets = _getScrapPresets();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Zone 1: Image Capture ──────────────────────────────
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.line),
              ),
              child: _buildImageOrCaptureArea(lang),
            ),
            const SizedBox(height: AppSpacing.md),

            // AI Result Card
            if (_aiResult != null)
              AppFadeIn(child: _buildAiResultCard(lang)),

            const SizedBox(height: AppSpacing.md),

            // ── Quick Samples ─────────────────────────────────────
            AppSectionLabel(
              switch (lang) {
                'mr' => 'नमुने निवडा',
                'en' => 'Quick Samples',
                _ => 'नमूने चुनें',
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: presets.length + _gizFieldSamples.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  if (index < presets.length) {
                    final p = presets[index];
                    final isActive = _benchmarkAssetPath == p.assetImg ||
                        _selectedSubCategory == p.subCat;
                    return _buildChip(
                      label: p.getName(lang),
                      icon: p.icon,
                      isActive: isActive,
                      onTap: () => _selectBenchmarkSample(
                          p.assetImg, p.subCat, p.defaultKg),
                    );
                  } else {
                    final s = _gizFieldSamples[index - presets.length];
                    final isActive = _benchmarkAssetPath == s.assetImg;
                    return _buildChip(
                      label: s.name,
                      icon: Icons.photo_library_outlined,
                      isActive: isActive,
                      onTap: () => _selectBenchmarkSample(
                          s.assetImg, _selectedSubCategory, 12.0),
                      muted: true,
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Zone 2: Classification & Weight ───────────────────
            AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    switch (lang) {
                      'mr' => 'साहित्य वर्गीकरण',
                      'en' => 'Classification',
                      _ => 'सामग्री वर्गीकरण',
                    },
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.ink),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Builder(
                    builder: (context) {
                      final safeDropdownValue = allPrices.any((p) => p.subCategory == _selectedSubCategory)
                          ? _selectedSubCategory
                          : (allPrices.isNotEmpty ? allPrices.first.subCategory : null);
                      return DropdownButtonFormField<String>(
                        value: safeDropdownValue,
                        decoration: InputDecoration(
                          labelText: switch (lang) {
                            'mr' => 'विशिष्ट वर्ग',
                            'en' => 'Sub-Category',
                            _ => 'विशिष्ट श्रेणी',
                          },
                        ),
                        isExpanded: true,
                        items: allPrices.map((p) {
                          return DropdownMenuItem<String>(
                            value: p.subCategory,
                            child: Text(
                              '${p.category}: ${p.subCategory}',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.ink),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final match =
                                allPrices.firstWhere((e) => e.subCategory == val, orElse: () => allPrices.first);
                            setState(() {
                              _selectedSubCategory = val;
                              _selectedCategory = match.category;
                            });
                            _recalcDensityFraud();
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: _conditionGrade,
                    decoration: InputDecoration(
                      labelText: switch (lang) {
                        'mr' => 'गुणवत्ता दर्जा',
                        'en' => 'Condition Grade',
                        _ => 'गुणवत्ता स्तर',
                      },
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'Grade A (Intact)',
                        child: Text(
                          switch (lang) {
                            'mr' => 'Grade A: संपूर्ण व स्वच्छ',
                            'en' => 'Grade A: Clean & Intact',
                            _ => 'Grade A: संपूर्ण व अप्रदूषित',
                          },
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.ink),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Grade B (Mixed)',
                        child: Text(
                          switch (lang) {
                            'mr' => 'Grade B: अंशतः मिश्रित',
                            'en' => 'Grade B: Mixed',
                            _ => 'Grade B: आंशिक मिश्रित',
                          },
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.ink),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Grade C (Broken)',
                        child: Text(
                          switch (lang) {
                            'mr' => 'Grade C: तुटलेले',
                            'en' => 'Grade C: Broken',
                            _ => 'Grade C: खंडित',
                          },
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.ink),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _conditionGrade = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Weight + Rate
            AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        switch (lang) {
                          'mr' => 'वजन (kg)',
                          'en' => 'Weight (kg)',
                          _ => 'वजन (कि.ग्रा.)',
                        },
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.ink),
                      ),
                      Text(
                        '₹${ratePerKg.toStringAsFixed(0)}/kg',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                            fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink),
                    decoration: InputDecoration(
                      suffixText: 'kg',
                      suffixStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted),
                      filled: true,
                      fillColor: AppColors.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(
                            color: AppColors.accent, width: 1.5),
                      ),
                    ),
                    onChanged: (_) => _recalcDensityFraud(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _buildQuickWeightBtn('+1', 1.0),
                      const SizedBox(width: AppSpacing.sm),
                      _buildQuickWeightBtn('+5', 5.0),
                      const SizedBox(width: AppSpacing.sm),
                      _buildQuickWeightBtn('+10', 10.0),
                      const SizedBox(width: AppSpacing.sm),
                      _buildQuickWeightBtn('+20', 20.0),
                    ],
                  ),
                ],
              ),
            ),

            // Fraud warning
            if (_fraudResult != null &&
                _fraudResult!.severity != FraudSeverity.clean) ...[
              const SizedBox(height: AppSpacing.md),
              AppFadeIn(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: _fraudResult!.severity == FraudSeverity.flag
                        ? AppColors.dangerSoft
                        : AppColors.warnSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: _fraudResult!.severity == FraudSeverity.flag
                          ? AppColors.dangerBorder
                          : AppColors.warnBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: _fraudResult!.severity == FraudSeverity.flag
                            ? AppColors.danger
                            : AppColors.warn,
                        size: 22,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          _fraudResult!.message ??
                              switch (lang) {
                                'mr' =>
                                  'वजन आणि आकार यांच्या प्रमाणात विसंगती.',
                                'en' => 'Unusual weight-to-volume ratio.',
                                _ =>
                                  'वजन और आकार अनुपात में असामान्य अंतर।',
                              },
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                _fraudResult!.severity == FraudSeverity.flag
                                    ? AppColors.danger
                                    : AppColors.warn,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // ── Zone 3: Valuation & Action ────────────────────────
            AppFadeIn(
              delay: const Duration(milliseconds: 100),
              child: AppSurface(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          switch (lang) {
                            'mr' => 'अंदाजे रोख रक्कम',
                            'en' => 'Estimated Value',
                            _ => 'अनुमानित नकद राशि',
                          },
                          style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                            border:
                                Border.all(color: AppColors.accentBorder),
                          ),
                          child: Text(
                            switch (lang) {
                              'mr' => 'थेट रोख',
                              'en' => 'Spot Cash',
                              _ => 'तुरंत नकद',
                            },
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '₹${totalValuation.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(height: 1, color: AppColors.lineSoft),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          switch (lang) {
                            'mr' => 'दलालापेक्षा अतिरिक्त नफा',
                            'en' => 'Bonus vs Middleman',
                            _ => 'दलाल से अतिरिक्त बचत',
                          },
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '+₹${collectorSurplus.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Create Lot Button
            FilledButton(
              onPressed: () => _createLot(
                  db, user, lang, totalValuation, weight),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    switch (lang) {
                      'mr' => 'लॉट तयार करा →',
                      'en' => 'Create Lot & Match →',
                      _ => 'लॉट बनाएं →',
                    },
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _createLot(AppDatabase db, dynamic user, String lang,
      double totalValuation, double weight) {
    if (weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (lang) {
            'mr' => 'कृपया योग्य वजन प्रविष्ट करा',
            'en' => 'Please enter a valid weight',
            _ => 'कृपया मान्य वजन दर्ज करें',
          }),
        ),
      );
      return;
    }

    final lotId =
        'LOT-2026-PUN-${const Uuid().v4().substring(0, 6).toUpperCase()}';
    final now = DateTime.now().millisecondsSinceEpoch;
    final hash = sha256
        .convert(utf8.encode('$lotId:$weight:$_selectedSubCategory'))
        .toString();

    final lot = MaterialsData(
      lotId: lotId,
      collectorId: user.id,
      category: _selectedCategory,
      subCategory: _selectedSubCategory,
      conditionGrade: _conditionGrade,
      estWeightKg: weight,
      estValuationInr: totalValuation,
      imageEdgeHash: hash.substring(0, 16),
      photoPath: _capturedImagePath ?? _benchmarkAssetPath,
      isFraudFlagged: _fraudResult?.severity == FraudSeverity.flag,
      fraudReason: _fraudResult?.message,
      lat: user.lat,
      lon: user.lon,
      createdAt: now,
    );

    db.insertMaterial(lot);

    db.addOutbox(OutboxData(
      id: const Uuid().v4(),
      entityType: 'MATERIAL_LOT',
      entityId: lotId,
      payloadJson: jsonEncode(lot.toMap()),
      status: 'PENDING',
      createdAt: now,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          switch (lang) {
            'mr' => 'डिजिटल लॉट $lotId तयार!',
            'en' => 'Lot $lotId created!',
            _ => 'लॉट $lotId बना!',
          },
        ),
        backgroundColor: AppColors.accent,
      ),
    );

    context.push('/lot/$lotId');
  }

  Widget _buildImageOrCaptureArea(String lang) {
    final hasImg =
        _capturedImagePath != null || _benchmarkAssetPath != null;

    if (hasImg) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: _capturedImagePath != null
                ? Image.file(File(_capturedImagePath!), fit: BoxFit.cover)
                : Image.asset(_benchmarkAssetPath!, fit: BoxFit.cover),
          ),
          if (_aiResult != null)
            CustomPaint(
              painter: _BoundingBoxPainter(bbox: _aiResult!.bbox),
            ),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: Colors.black45,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () => setState(() {
                _capturedImagePath = null;
                _benchmarkAssetPath = null;
                _aiResult = null;
              }),
            ),
          ),
          if (_isAnalyzing)
            Container(
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                    color: AppColors.accent, strokeWidth: 2.5),
              ),
            ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accentBorder),
          ),
          child: const Icon(Icons.photo_camera_outlined,
              size: 28, color: AppColors.accent),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          switch (lang) {
            'mr' => 'ई-कचऱ्याचा फोटो घ्या',
            'en' => 'Capture E-Waste Photo',
            _ => 'ई-कचरे की फोटो लें',
          },
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.ink),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: () => _takePhoto(ImageSource.camera),
              icon: const Icon(Icons.camera_alt, size: 16),
              label: Text(switch (lang) {
                'mr' => 'कॅमेरा',
                'en' => 'Camera',
                _ => 'कैमरा',
              }),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => _takePhoto(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined, size: 16),
              label: Text(switch (lang) {
                'mr' => 'गॅलरी',
                'en' => 'Gallery',
                _ => 'गैलरी',
              }),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAiResultCard(String lang) {
    final res = _aiResult!;
    final confidencePct = (res.confidence * 100).toStringAsFixed(1);

    return AppSurface(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      switch (lang) {
                        'mr' => res.marathiName,
                        'en' => res.category,
                        _ => res.hindiName,
                      },
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      res.subCategory,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$confidencePct%',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent),
                  ),
                  Text(
                    '${res.latencyMs}ms',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Confidence bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: res.confidence,
              backgroundColor: AppColors.lineSoft,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              // Model badge — Offline Edge ONNX AI
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.accentBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 11, color: AppColors.accentMuted),
                    SizedBox(width: 3),
                    Text(
                      'Edge ONNX AI (Offline)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (res.hazardLevel == 'HIGH') ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.dangerBorder),
                  ),
                  child: const Text(
                    '⚠ Hazard',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    bool muted = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          debugPrint('[UI] Chip tapped: $label');
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? (muted ? AppColors.accentMuted : AppColors.accent)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isActive
                  ? (muted ? AppColors.accentMuted : AppColors.accent)
                  : AppColors.line,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 14,
                  color: isActive ? Colors.white : AppColors.muted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.ink,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickWeightBtn(String label, double addKg) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          final cur = double.tryParse(_weightController.text) ?? 0.0;
          _weightController.text = (cur + addKg).toStringAsFixed(1);
          _recalcDensityFraud();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.line),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}

class _BoundingBoxPainter extends CustomPainter {
  final List<double> bbox;

  _BoundingBoxPainter({required this.bbox});

  @override
  void paint(Canvas canvas, Size size) {
    if (bbox.length < 4 || bbox.every((v) => v == 0)) return;

    final paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final left = (bbox[0] / 480.0) * size.width;
    final top = (bbox[1] / 640.0) * size.height;
    final right = (bbox[2] / 480.0) * size.width;
    final bottom = (bbox[3] / 640.0) * size.height;

    final rect = Rect.fromLTRB(left, top, right, bottom);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)), paint);

    // Corner markers
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    const cl = 12.0;
    canvas.drawLine(Offset(left, top), Offset(left + cl, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cl), cornerPaint);
    canvas.drawLine(Offset(right, top), Offset(right - cl, top), cornerPaint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cl), cornerPaint);
    canvas.drawLine(
        Offset(left, bottom), Offset(left + cl, bottom), cornerPaint);
    canvas.drawLine(
        Offset(left, bottom), Offset(left, bottom - cl), cornerPaint);
    canvas.drawLine(
        Offset(right, bottom), Offset(right - cl, bottom), cornerPaint);
    canvas.drawLine(
        Offset(right, bottom), Offset(right, bottom - cl), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _BoundingBoxPainter oldDelegate) =>
      oldDelegate.bbox != bbox;
}
