import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/app_state.dart';
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
  String _selectedCategory = 'PCB';
  String _selectedSubCategory = 'Mid Grade (Motherboards / GPUs)';
  String _conditionGrade = 'Grade A (Intact)';
  DensityFraudResult? _fraudResult;

  // Authentic e-waste scrap presets for quick photo simulation on emulator
  final List<({String name, String cat, String subCat, double defaultKg, IconData icon})> _scrapPresets = [
    (
      name: 'कंप्यूटर मदरबोर्ड (Motherboard)',
      cat: 'PCB',
      subCat: 'Mid Grade (Motherboards / GPUs)',
      defaultKg: 20.0,
      icon: Icons.developer_board,
    ),
    (
      name: 'तांबे की मोटी केबल (Copper Wire)',
      cat: 'Cables',
      subCat: 'Heavy Copper Cables (Insulated)',
      defaultKg: 10.0,
      icon: Icons.cable,
    ),
    (
      name: 'लैपटॉप/मोबाइल बैटरी (Li-Ion Battery)',
      cat: 'Batteries',
      subCat: 'Lithium-Ion Cells (Laptop / EV / Mobile)',
      defaultKg: 5.0,
      icon: Icons.battery_alert,
    ),
    (
      name: 'सीआरटी मॉनिटर ग्लास (CRT Glass)',
      cat: 'Displays',
      subCat: 'CRT Funnel Glass / Monitors',
      defaultKg: 15.0,
      icon: Icons.tv,
    ),
  ];

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024);
      if (picked != null) {
        setState(() {
          _capturedImagePath = picked.path;
        });
        _runDensityAnalysis();
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  void _runDensityAnalysis() {
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    if (weight <= 0) return;

    final subCatKey = switch (_selectedCategory) {
      'PCB' => 'motherboard',
      'Cables' => 'cable_copper',
      'Batteries' => 'battery_li',
      'Displays' => 'crt_monitor',
      _ => 'pcb',
    };

    // Analyze with realistic bounding box
    final res = DensityFraudDetector.analyse(
      bbox: [40, 60, 400, 480],
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
              // Photo / Camera Box
              Container(
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _capturedImagePath != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(File(_capturedImagePath!), fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton.filled(
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              onPressed: () => setState(() => _capturedImagePath = null),
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
                              child: const Text(
                                '✓ ई-कचरा फोटो कैप्चर संपन्न',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.photo_camera, size: 36, color: Color(0xFF1B5E20)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            switch (lang) {
                              'mr' => 'भंगाराचा फोटो घ्या किंवा नमुना निवडा',
                              'en' => 'Capture Photo or Select Scrap Sample',
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
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),

              // Scrap Sample Quick Selector (For instant demo testing)
              Text(
                switch (lang) {
                  'mr' => 'नमुना भंगार प्रकार (Quick Presets):',
                  'en' => 'Quick Scrap Presets:',
                  _ => 'त्वरित नमुना चयन (Quick Presets):',
                },
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
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
                    final isSelected = _selectedSubCategory == p.subCat;
                    return ActionChip(
                      avatar: Icon(p.icon, size: 18, color: isSelected ? Colors.white : const Color(0xFF1B5E20)),
                      label: Text(p.name),
                      backgroundColor: isSelected ? const Color(0xFF2E7D32) : Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedCategory = p.cat;
                          _selectedSubCategory = p.subCat;
                          _weightController.text = p.defaultKg.toString();
                        });
                        _runDensityAnalysis();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Category & Subcategory dropdowns
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'सामग्री विवरण (Material Classification)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedSubCategory,
                        decoration: InputDecoration(
                          labelText: 'विशिष्ट श्रेणी (Sub-Category)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        isExpanded: true,
                        items: allPrices.map((p) {
                          return DropdownMenuItem<String>(
                            value: p.subCategory,
                            child: Text('${p.category}: ${p.subCategory} (₹${p.netOfferedPrice.toStringAsFixed(0)}/kg)'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final match = allPrices.firstWhere((e) => e.subCategory == val);
                            setState(() {
                              _selectedSubCategory = val;
                              _selectedCategory = match.category;
                            });
                            _runDensityAnalysis();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _conditionGrade,
                        decoration: InputDecoration(
                          labelText: 'गुणवत्ता / ग्रेड (Condition Grade)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Grade A (Intact)', child: Text('Grade A: संपूर्ण व अप्रदूषित (Clean / Intact)')),
                          DropdownMenuItem(value: 'Grade B (Mixed)', child: Text('Grade B: आंशिक मिश्रित (Moderate Mixed)')),
                          DropdownMenuItem(value: 'Grade C (Broken)', child: Text('Grade C: खंडित / टूटा हुआ (Broken)')),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'प्रति किलो: ₹${ratePerKg.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          suffixText: 'kg (किलो)',
                          suffixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (_) => _runDensityAnalysis(),
                      ),
                      const SizedBox(height: 10),
                      // Quick weight buttons
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
              if (_fraudResult != null && _fraudResult!.severity != FraudSeverity.clean) ...[
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
                          _fraudResult!.message ?? 'वजन और आकार अनुपात में असामान्य अंतर पाया गया।',
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
                      color: Colors.green.withOpacity(0.3),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade400,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'तुरंत नकद (Spot Cash)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
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
                          style: TextStyle(fontSize: 12, color: Colors.green.shade100),
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
                  final finalWeight = double.tryParse(_weightController.text) ?? 0.0;
                  if (finalWeight <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('कृपया मान्य वजन दर्ज करें')),
                    );
                    return;
                  }

                  final lotId = 'LOT-2026-PUN-${const Uuid().v4().substring(0, 6).toUpperCase()}';
                  final now = DateTime.now().millisecondsSinceEpoch;
                  final hash = sha256.convert(utf8.encode('$lotId:$finalWeight:$_selectedSubCategory')).toString();

                  final lot = MaterialsData(
                    lotId: lotId,
                    collectorId: user.id,
                    category: _selectedCategory,
                    subCategory: _selectedSubCategory,
                    conditionGrade: _conditionGrade,
                    estWeightKg: finalWeight,
                    estValuationInr: totalValuation,
                    imageEdgeHash: hash.substring(0, 16),
                    photoPath: _capturedImagePath,
                    isFraudFlagged: _fraudResult?.severity == FraudSeverity.flag,
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
                      content: Text('डिजिटल लॉट $lotId सफलतापूर्वक बना! रिसाइक्लर चुनें।'),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickWeightBtn(String label, double addKg) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          final curr = double.tryParse(_weightController.text) ?? 0.0;
          setState(() {
            _weightController.text = (curr + addKg).toStringAsFixed(1);
          });
          _runDensityAnalysis();
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          side: BorderSide(color: Colors.green.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800),
        ),
      ),
    );
  }
}
