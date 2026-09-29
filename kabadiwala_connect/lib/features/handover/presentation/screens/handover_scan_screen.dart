import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/app_state.dart';
import '../../../../core/storage/database.dart';
import '../../../../core/storage/models.dart';
import '../../../../core/utils/qr_signer.dart';

class HandoverScanScreen extends ConsumerStatefulWidget {
  const HandoverScanScreen({super.key, this.initialQrBlob});

  final String? initialQrBlob;

  @override
  ConsumerState<HandoverScanScreen> createState() => _HandoverScanScreenState();
}

class _HandoverScanScreenState extends ConsumerState<HandoverScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final _manualInputController = TextEditingController();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialQrBlob != null && widget.initialQrBlob!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _verifyAndProceed(widget.initialQrBlob!);
      });
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  void _verifyAndProceed(String rawQrText) {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final db = ref.read(databaseProvider);
    final user = ref.read(appStateProvider);
    final lang = user.language;
    final verification = QrSigner.verify(rawQrText);

    if (!verification.valid || verification.payload == null) {
      setState(() {
        _isProcessing = false;
        _errorMessage = verification.error ??
            switch (lang) {
              'mr' => 'अवैध डिजिटल क्यूआर स्वाक्षरी (Invalid Cryptographic Token)',
              'en' => 'Invalid Cryptographic QR Token Signature',
              _ => 'अमान्य डिजिटल क्यूआर हस्ताक्षर (Invalid Cryptographic Token)',
            };
      });
      return;
    }

    final data = verification.payload!;
    final lotId = data['lot_id'] as String;
    final txId = data['tx_id'] as String;
    final now = DateTime.now().millisecondsSinceEpoch;
    final traceId = 'TRACE-2026-${const Uuid().v4().substring(0, 6).toUpperCase()}';

    // Insert pending traceability record
    db.insertTraceability(TraceabilityData(
      traceId: traceId,
      lotId: lotId,
      txId: txId,
      handoverQrHash: sha256.convert(utf8.encode(rawQrText)).toString(),
      edgeTimestamp: now,
      handoverLat: (data['lat'] as num?)?.toDouble() ?? user.lat,
      handoverLon: (data['lon'] as num?)?.toDouble() ?? user.lon,
      verificationStatus: 'PENDING_PHYSICAL_WEIGHING',
      cpcbBatchId: 'BATCH-CPCB-MH-${now.toString().substring(6, 12)}',
      createdAt: now,
    ));

    // Navigate to Recycler Confirm Screen
    context.pushReplacement('/handover/confirm/$traceId');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appStateProvider);
    final lang = user.language;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          switch (lang) {
            'mr' => 'रिसायकलर क्यूआर स्कॅनर',
            'en' => 'Recycler QR Scanner',
            _ => 'रीसाइक्लर क्यूआर स्कैनर',
          },
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Error banner if any
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: const Color(0xFFDC2626),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            // Live Camera Scanner
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: (capture) {
                      final barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        final rawValue = barcode.rawValue;
                        if (rawValue != null && rawValue.isNotEmpty) {
                          _verifyAndProceed(rawValue);
                          break;
                        }
                      }
                    },
                  ),
                  // Reticle overlay
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF10B981), width: 2.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  if (_isProcessing)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Color(0xFF10B981)),
                            const SizedBox(height: 12),
                            Text(
                              switch (lang) {
                                'mr' => 'डिजिटल टोकन पडताळणी सुरू आहे...',
                                'en' => 'Verifying cryptographic token...',
                                _ => 'क्रिप्टोग्राफिक टोकन सत्यापित हो रहा है...',
                              },
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom manual test action panel
            Container(
              color: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    switch (lang) {
                      'mr' => 'कलेक्टरच्या फोनमधील क्यूआर कोड स्कॅनरसमोर धरा',
                      'en' => 'Align collector\'s QR code within the frame',
                      _ => 'कलेक्टर के फोन का डिजिटल क्यूआर स्क्रीन के सामने रखें',
                    },
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  // Quick test button using latest quoted transaction in DB
                  OutlinedButton.icon(
                    onPressed: () {
                      final db = ref.read(databaseProvider);
                      final allLots = db.getAllMaterials();
                      if (allLots.isNotEmpty) {
                        final latestLot = allLots.first;
                        final latestTx = db.getTransactionByLotId(latestLot.lotId);
                        if (latestTx != null) {
                          final payload = QrSigner.buildPayload(
                            txId: latestTx.txId,
                            lotId: latestLot.lotId,
                            collectorId: latestLot.collectorId,
                            lat: latestLot.lat ?? user.lat,
                            lon: latestLot.lon ?? user.lon,
                            category: latestLot.category,
                            subCategory: latestLot.subCategory,
                            estWeightKg: latestLot.estWeightKg,
                            quotedValueInr: latestTx.quotedValueInr,
                            netOfferedPriceInr: latestTx.finalSettledInr,
                          );
                          final blob = QrSigner.sign(payload);
                          _verifyAndProceed(blob);
                        }
                      }
                    },
                    icon: const Icon(Icons.flash_on, color: Color(0xFFFBBF24)),
                    label: Text(
                      switch (lang) {
                        'mr' => 'त्वरित चाचणी: नवीनतम लॉट पडताळा',
                        'en' => 'Quick Test: Verify Latest Lot',
                        _ => 'त्वरित परीक्षण: नवीनतम लॉट सत्यापित करें',
                      },
                      style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFBBF24)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
