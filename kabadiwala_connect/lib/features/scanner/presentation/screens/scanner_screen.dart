import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/app_state.dart';
import '../../../../core/services/ai_inference_service.dart';
import '../../../../core/storage/database.dart';
import '../../../../core/storage/models.dart';
import '../../../../core/utils/density_fraud_detector.dart';

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
      name: 'GIZ Field #1 (Mixed Waste)',
      assetImg: 'assets/images/test_samples/IMG_20250522_115902_928.jpg',
    ),
    (
      name: 'GIZ Field #2 (Electronic Lot)',
      assetImg: 'assets/images/test_samples/IMG_20250522_115909_024.jpg',
    ),
    (
      name: 'GIZ Field #3 (Scrap Pile)',
      assetImg: 'assets/images/test_samples/IMG_20250522_121901_241.jpg',
    ),
    (
      name: 'GIZ Field #4 (Disassembly)',
      assetImg: 'assets/images/test_samples/IMG_20250522_125712_264.jpg',
    ),
  ];

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto(ImageSource source) async {
    try {
      final picked =
          await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024);
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

  Future<void> _selectBenchmarkSample(String assetPath, String defaultSubCat, double defaultKg) async {
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

    setState(() {
      _aiResult = result;
      _selectedCategory = result.category;
      _selectedSubCategory = result.subCategory;
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

    setState(() {
      _fraudResult = res;
    });
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Minimalist Photo / Camera Box with AI Bounding Box HUD
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildImageOrCaptureArea(lang),
              ),
              const SizedBox(height: 12),

              // AI Inference HUD Card
              if (_aiResult != null) _buildAiInferenceHud(lang),

              const SizedBox(height: 16),

              // Scrap Sample Quick Selector (SIH Benchmarks)
              Text(
                switch (lang) {
                  'mr' => 'नमुना ई-कचरा निवडा:',
                  'en' => 'Benchmark E-Waste Samples:',
                  _ => 'त्वरित ई-कचरा नमुना चुनें:',
                },
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: presets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final p = presets[index];
                    final isSelected = _benchmarkAssetPath == p.assetImg ||
                        _selectedSubCategory == p.subCat;
                    return GestureDetector(
                      onTap: () => _selectBenchmarkSample(p.assetImg, p.subCat, p.defaultKg),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF059669) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              p.icon,
                              size: 16,
                              color: isSelected ? Colors.white : const Color(0xFF059669),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              p.getName(lang),
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF334155),
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // GIZ Real E-Waste Field Samples Bar
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _gizFieldSamples.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final s = _gizFieldSamples[index];
                    final isSelected = _benchmarkAssetPath == s.assetImg;
                    return GestureDetector(
                      onTap: () => _selectBenchmarkSample(s.assetImg, _selectedSubCategory, 12.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 13,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              s.name,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.white : const Color(0xFF334155),
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Category & Subcategory card (Clean Minimalist White)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      switch (lang) {
                        'mr' => 'साहित्य वर्गीकरण',
                        'en' => 'Material Classification',
                        _ => 'सामग्री वर्गीकरण',
                      },
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSubCategory,
                      decoration: InputDecoration(
                        labelText: switch (lang) {
                          'mr' => 'विशिष्ट वर्ग',
                          'en' => 'Specific Sub-Category',
                          _ => 'विशिष्ट श्रेणी',
                        },
                        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      isExpanded: true,
                      items: allPrices.map((p) {
                        return DropdownMenuItem<String>(
                          value: p.subCategory,
                          child: Text(
                            '${p.category}: ${p.subCategory} (₹${p.netOfferedPrice.toStringAsFixed(0)}/kg)',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final match = allPrices.firstWhere((e) => e.subCategory == val);
                          setState(() {
                            _selectedSubCategory = val;
                            _selectedCategory = match.category;
                          });
                          _recalcDensityFraud();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _conditionGrade,
                      decoration: InputDecoration(
                        labelText: switch (lang) {
                          'mr' => 'गुणवत्ता दर्जा (ग्रेड)',
                          'en' => 'Condition Grade',
                          _ => 'गुणवत्ता स्तर (ग्रेड)',
                        },
                        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Grade B (Mixed)',
                          child: Text(
                            switch (lang) {
                              'mr' => 'Grade B: अंशतः मिश्रित',
                              'en' => 'Grade B: Moderately Mixed',
                              _ => 'Grade B: आंशिक मिश्रित',
                            },
                            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Grade C (Broken)',
                          child: Text(
                            switch (lang) {
                              'mr' => 'Grade C: तुटलेले / तुकडे',
                              'en' => 'Grade C: Broken Pieces',
                              _ => 'Grade C: खंडित / टूटा हुआ',
                            },
                            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
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
              const SizedBox(height: 14),

              // Weight Input & Presets Card (Minimalist)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          switch (lang) {
                            'mr' => 'काट्यावरील वजन (kg)',
                            'en' => 'Scale Weight (kg)',
                            _ => 'तराजू वजन (कि.ग्रा.)',
                          },
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          switch (lang) {
                            'mr' => 'दर: ₹${ratePerKg.toStringAsFixed(0)}/किलो',
                            'en' => 'Rate: ₹${ratePerKg.toStringAsFixed(0)}/kg',
                            _ => 'दर: ₹${ratePerKg.toStringAsFixed(0)}/कि.ग्रा.',
                          },
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF059669), fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        suffixText: switch (lang) {
                          'mr' => 'किलो',
                          'en' => 'kg',
                          _ => 'कि.ग्रा.',
                        },
                        suffixStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF059669), width: 1.8),
                        ),
                      ),
                      onChanged: (_) => _recalcDensityFraud(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildQuickWeightBtn('+1 kg', 1.0),
                        const SizedBox(width: 8),
                        _buildQuickWeightBtn('+5 kg', 5.0),
                        const SizedBox(width: 8),
                        _buildQuickWeightBtn('+10 kg', 10.0),
                        const SizedBox(width: 8),
                        _buildQuickWeightBtn('+20 kg', 20.0),
                      ],
                    ),
                  ],
                ),
              ),

              // Fraud / Anomaly warning banner if triggered
              if (_fraudResult != null && _fraudResult!.severity != FraudSeverity.clean) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _fraudResult!.severity == FraudSeverity.flag
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _fraudResult!.severity == FraudSeverity.flag
                          ? const Color(0xFFFECACA)
                          : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: _fraudResult!.severity == FraudSeverity.flag
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFD97706),
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _fraudResult!.message ??
                              switch (lang) {
                                'mr' => 'वजन आणि आकार यांच्या प्रमाणात विसंगती आढळली.',
                                'en' => 'Unusual weight-to-volume ratio detected.',
                                _ => 'वजन और आकार अनुपात में असामान्य अंतर पाया गया।',
                              },
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _fraudResult!.severity == FraudSeverity.flag
                                ? const Color(0xFF991B1B)
                                : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Valuation Summary Card (Clean Minimalist White with Emerald Accents)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          switch (lang) {
                            'mr' => 'अंदाजे देय रोख रक्कम:',
                            'en' => 'Estimated Cash Value:',
                            _ => 'अनुमानित देय नकद राशि:',
                          },
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Text(
                            switch (lang) {
                              'mr' => 'थेट रोख रक्कम',
                              'en' => 'Spot Cash',
                              _ => 'तुरंत नकद',
                            },
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${totalValuation.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(height: 1, color: const Color(0xFFF1F5F9)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          switch (lang) {
                            'mr' => 'स्थानिक दलालापेक्षा अतिरिक्त नफा:',
                            'en' => 'Bonus vs Middleman:',
                            _ => 'स्थानीय दलाल की तुलना में अतिरिक्त बचत:',
                          },
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '+₹${collectorSurplus.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Create Lot Action Button
              FilledButton(
                onPressed: () {
                  final finalWeight = double.tryParse(_weightController.text) ?? 0.0;
                  if (finalWeight <= 0) {
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

                  final lotId = 'LOT-2026-PUN-${const Uuid().v4().substring(0, 6).toUpperCase()}';
                  final now = DateTime.now().millisecondsSinceEpoch;
                  final hash = sha256
                      .convert(utf8.encode('$lotId:$finalWeight:$_selectedSubCategory'))
                      .toString();

                  final lot = MaterialsData(
                    lotId: lotId,
                    collectorId: user.id,
                    category: _selectedCategory,
                    subCategory: _selectedSubCategory,
                    conditionGrade: _conditionGrade,
                    estWeightKg: finalWeight,
                    estValuationInr: totalValuation,
                    imageEdgeHash: hash.substring(0, 16),
                    photoPath: _capturedImagePath ?? _benchmarkAssetPath,
                    isFraudFlagged: _fraudResult?.severity == FraudSeverity.flag,
                    fraudReason: _fraudResult?.message,
                    lat: user.lat,
                    lon: user.lon,
                    createdAt: now,
                  );

                  // Insert into real SQLite database
                  db.insertMaterial(lot);

                  // Enqueue outbox for sync
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
                          'mr' => 'डिजिटल लॉट $lotId यशस्वीरीत्या तयार झाला!',
                          'en' => 'Digital Lot $lotId successfully created!',
                          _ => 'डिजिटल लॉट $lotId सफलतापूर्वक बना!',
                        },
                      ),
                      backgroundColor: const Color(0xFF059669),
                    ),
                  );

                  // Navigate to Lot Details / Recycler Match
                  context.push('/lot/$lotId');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      switch (lang) {
                        'mr' => 'लॉट सेव्ह करा आणि रिसायकलर निवडा →',
                        'en' => 'Create Lot & Match Recyclers →',
                        _ => 'लॉट सुरक्षित करें और रीसाइक्लर चुनें →',
                      },
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageOrCaptureArea(String lang) {
    final hasImg = _capturedImagePath != null || _benchmarkAssetPath != null;

    if (hasImg) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: _capturedImagePath != null
                ? Image.file(File(_capturedImagePath!), fit: BoxFit.cover)
                : Image.asset(_benchmarkAssetPath!, fit: BoxFit.cover),
          ),
          if (_aiResult != null)
            CustomPaint(
              painter: _BoundingBoxPainter(bbox: _aiResult!.bbox),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
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
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xCC0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Color(0xFF34D399)),
                  const SizedBox(width: 4),
                  Text(
                    _isAnalyzing
                        ? switch (lang) {
                            'mr' => 'AI विश्लेषण सुरू आहे...',
                            'en' => 'AI analyzing pixels...',
                            _ => 'AI विश्लेषण प्रगति पर है...',
                          }
                        : switch (lang) {
                            'mr' => '✓ फोटो लोड झाला',
                            'en' => '✓ Image Loaded & Scanned',
                            _ => '✓ ई-कचरा फोटो लोड संपन्न',
                          },
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: const Icon(Icons.photo_camera_outlined, size: 32, color: Color(0xFF059669)),
        ),
        const SizedBox(height: 10),
        Text(
          switch (lang) {
            'mr' => 'ई-कचऱ्याचा फोटो घ्या किंवा नमुना निवडा',
            'en' => 'Capture E-Waste Photo or Select Sample',
            _ => 'ई-कचरे की फोटो लें या नीचे से नमुना चुनें',
          },
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 12),
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
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => _takePhoto(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined, size: 16),
              label: Text(switch (lang) {
                'mr' => 'गॅलरी',
                'en' => 'Gallery',
                _ => 'गैलरी',
              }),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                minimumSize: const Size(0, 38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAiInferenceHud(String lang) {
    final res = _aiResult!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF059669)),
                  const SizedBox(width: 6),
                  Text(
                    'AI Edge Detection: ${res.category}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${(res.confidence * 100).toStringAsFixed(1)}% Conf • ${res.latencyMs}ms',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                switch (lang) {
                  'mr' => 'ओळख: ${res.marathiName}',
                  'en' => 'Identified: ${res.subCategory}',
                  _ => 'पहचान: ${res.hindiName}',
                },
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const Spacer(),
              if (res.hazardLevel == 'HIGH')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, size: 11, color: Color(0xFFDC2626)),
                      const SizedBox(width: 4),
                      Text(
                        'Hazard: ${res.hazardDescription}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
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
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Color(0xFF334155),
            ),
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
    if (bbox.length < 4) return;

    final paint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Scale bbox from 480x640 reference to view size
    final left = (bbox[0] / 480.0) * size.width;
    final top = (bbox[1] / 640.0) * size.height;
    final right = (bbox[2] / 480.0) * size.width;
    final bottom = (bbox[3] / 640.0) * size.height;

    final rect = Rect.fromLTRB(left, top, right, bottom);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);

    // Draw Corner markers
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    const cornerLen = 14.0;
    // Top-left
    canvas.drawLine(Offset(left, top), Offset(left + cornerLen, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLen), cornerPaint);
    // Top-right
    canvas.drawLine(Offset(right, top), Offset(right - cornerLen, top), cornerPaint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerLen), cornerPaint);
    // Bottom-left
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerLen, bottom), cornerPaint);
    canvas.drawLine(Offset(left, bottom), Offset(left, bottom - cornerLen), cornerPaint);
    // Bottom-right
    canvas.drawLine(Offset(right, bottom), Offset(right - cornerLen, bottom), cornerPaint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - cornerLen), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _BoundingBoxPainter oldDelegate) => oldDelegate.bbox != bbox;
}
