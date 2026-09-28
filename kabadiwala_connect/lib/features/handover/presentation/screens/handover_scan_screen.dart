import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

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
    final verification = QrSigner.verify(rawQrText);

    if (!verification.valid || verification.payload == null) {
      setState(() {
        _isProcessing = false;
        _errorMessage = verification.error ?? 'अमान्य डिजिटल क्यूआर हस्ताक्षर (Invalid Cryptographic Token)';
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
      handoverQrHash: rawQrText.hashCode.toString(),
      edgeTimestamp: now,
      handoverLat: (data['lat'] as num?)?.toDouble() ?? 18.5204,
      handoverLon: (data['lon'] as num?)?.toDouble() ?? 73.8567,
      verificationStatus: 'PENDING_PHYSICAL_WEIGHING',
      cpcbBatchId: 'BATCH-CPCB-MH-${now.toString().substring(6, 12)}',
      createdAt: now,
    ));

    // Navigate to Recycler Confirm Screen
    context.pushReplacement('/handover/$traceId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('रिसाइक्लर क्यूआर स्कैनर (Recycler Scanner)'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Error banner if any
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade900,
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
                      border: Border.all(color: Colors.greenAccent, width: 2.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  if (_isProcessing)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.greenAccent),
                            SizedBox(height: 12),
                            Text(
                              'क्रिप्टोग्राफिक टोकन सत्यापित हो रहा है…',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              color: const Color(0xFF1E1E1E),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'कलेक्टर के फोन का डिजिटल क्यूआर स्क्रीन के सामने रखें',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
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
                            lat: 18.5204,
                            lon: 73.8567,
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
                    icon: const Icon(Icons.flash_on, color: Colors.amberAccent),
                    label: const Text(
                      'त्वरित परीक्षण: नवीनतम लॉट सत्यापित करें',
                      style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.amberAccent),
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
