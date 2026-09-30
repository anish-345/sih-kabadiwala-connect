import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_theme.dart';
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
              'mr' => 'अवैध डिजिटल क्यूआर स्वाक्षरी',
              'en' => 'Invalid QR Token Signature',
              _ => 'अमान्य डिजिटल क्यूआर हस्ताक्षर',
            };
      });
      return;
    }

    final data = verification.payload!;
    final lotId = data['lot_id'] as String;
    final txId = data['tx_id'] as String;
    final now = DateTime.now().millisecondsSinceEpoch;
    final traceId =
        'TRACE-2026-${const Uuid().v4().substring(0, 6).toUpperCase()}';

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
            'mr' => 'क्यूआर स्कॅनर',
            'en' => 'QR Scanner',
            _ => 'क्यूआर स्कैनर',
          },
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.line),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Error banner
            if (_errorMessage != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                color: AppColors.danger,
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.white, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 18),
                      onPressed: () =>
                          setState(() => _errorMessage = null),
                    ),
                  ],
                ),
              ),

            // Camera scanner
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
                  // Scan reticle
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.8),
                          width: 2),
                      borderRadius:
                          BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  // Corner accents
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CustomPaint(painter: _ReticlePainter()),
                  ),
                  if (_isProcessing)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                                color: AppColors.accent,
                                strokeWidth: 2.5),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              switch (lang) {
                                'mr' => 'टोकन पडताळणी...',
                                'en' => 'Verifying token...',
                                _ => 'टोकन सत्यापन...',
                              },
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom panel
            Container(
              color: AppColors.ink,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      switch (lang) {
                        'mr' =>
                          'कलेक्टरचा क्यूआर कोड फ्रेममध्ये ठेवा',
                        'en' =>
                          'Align collector\'s QR code in the frame',
                        _ =>
                          'कलेक्टर का क्यूआर कोड फ्रेम में रखें',
                      },
                      style: const TextStyle(
                          color: AppColors.subtle, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: () {
                        final db = ref.read(databaseProvider);
                        final allLots = db.getAllMaterials();
                        if (allLots.isNotEmpty) {
                          final latestLot = allLots.first;
                          final latestTx = db
                              .getTransactionByLotId(latestLot.lotId);
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
                              netOfferedPriceInr:
                                  latestTx.finalSettledInr,
                            );
                            final blob = QrSigner.sign(payload);
                            _verifyAndProceed(blob);
                          }
                        }
                      },
                      icon: const Icon(Icons.flash_on,
                          color: AppColors.warn, size: 18),
                      label: Text(
                        switch (lang) {
                          'mr' => 'त्वरित चाचणी',
                          'en' => 'Quick Test',
                          _ => 'त्वरित परीक्षण',
                        },
                        style: const TextStyle(
                            color: AppColors.warn,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.warn),
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const c = 24.0;
    final w = size.width;
    final h = size.height;

    // Top-left
    canvas.drawLine(Offset.zero, Offset(c, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, c), paint);
    // Top-right
    canvas.drawLine(Offset(w, 0), Offset(w - c, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, c), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, h), Offset(c, h), paint);
    canvas.drawLine(Offset(0, h), Offset(0, h - c), paint);
    // Bottom-right
    canvas.drawLine(Offset(w, h), Offset(w - c, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - c), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
