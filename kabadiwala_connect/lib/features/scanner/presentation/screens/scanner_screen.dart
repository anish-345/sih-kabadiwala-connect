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

  // Authentic e-waste scrap presets for instant testing & SIH evaluation
  final List<({
    String name,
    String cat,
    String subCat,
    double defaultKg,
    IconData icon,
    String assetImg,
  })> _scrapPresets = [
    (
      name: 'मदरबोर्ड (Motherboard)',
      cat: 'PCB',
      subCat: 'Mid Grade (Motherboards / GPUs)',
      defaultKg: 20.0,
      icon: Icons.developer_board,
      assetImg: 'assets/images/benchmark/motherboard_sample.jpg',
    ),
    (
      name: 'तांबा केबल (Copper Wire)',
      cat: 'Cables',
      subCat: 'Heavy Copper Cables (Insulated)',
      defaultKg: 10.0,
      icon: Icons.cable,
      assetImg: 'assets/images/benchmark/copper_cable_sample.jpg',
    ),
    (
      name: 'लिथियम बैटरी (Li-Ion Battery)',
      cat: 'Batteries',
      subCat: 'Lithium-Ion Cells (Laptop / EV / Mobile)',
      defaultKg: 5.0,
      icon: Icons.battery_alert,
      assetImg: 'assets/images/benchmark/battery_li_sample.jpg',
    ),
    (
      name: 'सीआरटी ग्लास (CRT Glass)',
      cat: 'Displays',
      subCat: 'CRT Funnel Glass / Monitors',
      defaultKg: 15.0,
      icon: Icons.tv,
      assetImg: 'assets/images/benchmark/crt_glass_sample.jpg',
    ),
  ];

  // Authentic GIZ field dataset photos for real-world validation
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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo / Camera Box with AI Bounding Box HUD
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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
                  'mr' => 'नमुना भंगार प्रकार (SIH Benchmarks):',
                  'en' => 'SIH 26229 Benchmark Scrap Samples:',
                  _ => 'त्वरित नमुना चयन (SIH 26229 Benchmarks):',
                },
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _scrapPresets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final p = _scrapPresets[index];
                    final isSelected = _benchmarkAssetPath == p.assetImg ||
                        _selectedSubCategory == p.subCat;
                    return ActionChip(
                      avatar: Icon(p.icon,
                          size: 18,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1B5E20)),
                      label: Text(p.name),
                      backgroundColor:
                          isSelected ? const Color(0xFF2E7D32) : Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onPressed: () => _selectBenchmarkSample(
                          p.assetImg, p.subCat, p.defaultKg),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // GIZ Real E-Waste Field Samples Bar
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _gizFieldSamples.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final s = _gizFieldSamples[index];
                    final isSelected = _benchmarkAssetPath == s.assetImg;
                    return ActionChip(
                      avatar: const Icon(Icons.photo_library_outlined, size: 14),
                      label: Text(s.name, style: const TextStyle(fontSize: 11)),
                      backgroundColor:
                          isSelected ? Colors.teal.shade700 : Colors.teal.shade50,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.teal.shade900,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onPressed: () =>
                          _selectBenchmarkSample(s.assetImg, _selectedSubCategory, 12.0),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Category & Subcategory dropdowns
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'सामग्री वर्गीकरण (Material Classification)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSubCategory,
                        decoration: InputDecoration(
                          labelText: 'विशिष्ट श्रेणी (Sub-Category)',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        isExpanded: true,
                        items: allPrices.map((p) {
                          return DropdownMenuItem<String>(
                            value: p.subCategory,
                            child: Text(
                                '${p.category}: ${p.subCategory} (₹${p.netOfferedPrice.toStringAsFixed(0)}/kg)'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final match =
                                allPrices.firstWhere((e) => e.subCategory == val);
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
                          labelText: 'गुणवत्ता / ग्रेड (Condition Grade)',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Grade A (Intact)',
                              child: Text(
                                  'Grade A: संपूर्ण व अप्रदूषित (Clean / Intact)')),
                          DropdownMenuItem(
                              value: 'Grade B (Mixed)',
                              child: Text(
                                  'Grade B: आंशिक मिश्रित (Moderate Mixed)')),
                          DropdownMenuItem(
                              value: 'Grade C (Broken)',
                              child: Text(
                                  'Grade C: खंडित / टूटा हुआ (Broken)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _conditionGrade = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Weight Input & Presets
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'तराजू वजन (Scale Weight in kg)',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'प्रति किलो: ₹${ratePerKg.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _weightController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          suffixText: 'kg (किलो)',
                          suffixStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
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
              ),

              // Fraud / Anomaly warning banner if triggered
              if (_fraudResult != null &&
                  _fraudResult!.severity != FraudSeverity.clean) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _fraudResult!.severity == FraudSeverity.flag
                        ? Colors.red.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _fraudResult!.severity == FraudSeverity.flag
                          ? Colors.red.shade400
                          : Colors.orange.shade400,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: _fraudResult!.severity == FraudSeverity.flag
                            ? Colors.red.shade800
                            : Colors.orange.shade800,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _fraudResult!.message ??
                              'वजन और आकार अनुपात में असामान्य अंतर पाया गया।',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _fraudResult!.severity == FraudSeverity.flag
                                ? Colors.red.shade900
                                : Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Valuation Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'अनुमानित देय नकद राशि:',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade400,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'तुरंत नकद (Spot Cash)',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${totalValuation.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Divider(color: Colors.white30, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'स्थानीय दलाल की तुलना में अतिरिक्त लाभ:',
                          style: TextStyle(
                              fontSize: 12, color: Colors.green.shade100),
                        ),
                        Text(
                          '+₹${collectorSurplus.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD54F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Create Lot Action Button
              FilledButton.icon(
                onPressed: () {
                  final finalWeight =
                      double.tryParse(_weightController.text) ?? 0.0;
                  if (finalWeight <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('कृपया मान्य वजन दर्ज करें')),
                    );
                    return;
                  }

                  final lotId =
                      'LOT-2026-PUN-${const Uuid().v4().substring(0, 6).toUpperCase()}';
                  final now = DateTime.now().millisecondsSinceEpoch;
                  final hash = sha256
                      .convert(
                          utf8.encode('$lotId:$finalWeight:$_selectedSubCategory'))
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
                    isFraudFlagged:
                        _fraudResult?.severity == FraudSeverity.flag,
                    fraudReason: _fraudResult?.message,
                    lat: 18.5204,
                    lon: 73.8567,
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
                          'डिजिटल लॉट $lotId सफलतापूर्वक बना! रिसाइक्लर चुनें।'),
                      backgroundColor: Colors.green.shade800,
                    ),
                  );

                  // Navigate to Lot Details / Recycler Match
                  context.push('/lot/$lotId');
                },
                icon: const Icon(Icons.check_circle_outline, size: 22),
                label: Text(
                  switch (lang) {
                    'mr' => 'लॉट सेव्ह करा आणि रिसायकलर निवडा →',
                    'en' => 'Save Lot & Match Recyclers →',
                    _ => 'लॉट सुरक्षित करें और रिसाइक्लर चुनें →',
                  },
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
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
            borderRadius: BorderRadius.circular(16),
            child: _capturedImagePath != null
                ? Image.file(File(_capturedImagePath!), fit: BoxFit.cover)
                : Image.asset(_benchmarkAssetPath!, fit: BoxFit.cover),
          ),
          // Bounding Box Overlay if AI detected
          if (_aiResult != null)
            CustomPaint(
              painter: _BoundingBoxPainter(bbox: _aiResult!.bbox),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              icon: const Icon(Icons.refresh, color: Colors.white),
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
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Colors.greenAccent),
                  const SizedBox(width: 4),
                  Text(
                    _isAnalyzing
                        ? 'AI विश्लेषण प्रगति पर है...'
                        : '✓ AI ई-कचरा फोटो लोड संपन्न',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
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
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.photo_camera,
              size: 36, color: Color(0xFF1B5E20)),
        ),
        const SizedBox(height: 8),
        Text(
          switch (lang) {
            'mr' => 'भंगाराचा फोटो घ्या किंवा खालील नमुना निवडा',
            'en' => 'Capture Photo or Select SIH Benchmark Sample',
            _ => 'ई-कचरे की फोटो लें या नीचे से नमुना चुनें',
          },
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _takePhoto(ImageSource.camera),
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text('कैमरा (Camera)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => _takePhoto(ImageSource.gallery),
              icon: const Icon(Icons.photo_library, size: 18),
              label: const Text('गैलरी (Gallery)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1B5E20),
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF81C784)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF1B5E20)),
                  const SizedBox(width: 6),
                  Text(
                    'AI Edge Detection: ${res.category}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(res.confidence * 100).toStringAsFixed(1)}% Conf • ${res.latencyMs}ms',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'पहचान: ${res.hindiName} / ${res.marathiName}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800),
              ),
              const Spacer(),
              if (res.hazardLevel == 'HIGH')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade400),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, size: 12, color: Colors.red.shade800),
                      const SizedBox(width: 4),
                      Text(
                        'Hazard: ${res.hazardDescription}',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900),
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
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(vertical: 8),
          side: BorderSide(color: Colors.green.shade400),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          final cur = double.tryParse(_weightController.text) ?? 0.0;
          _weightController.text = (cur + addKg).toStringAsFixed(1);
          _recalcDensityFraud();
        },
        child: Text(
          label,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF1B5E20)),
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
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

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
      ..strokeWidth = 4.0;

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
  bool shouldRepaint(covariant _BoundingBoxPainter oldDelegate) =>
      oldDelegate.bbox != bbox;
}
