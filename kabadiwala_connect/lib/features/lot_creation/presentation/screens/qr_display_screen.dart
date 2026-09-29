import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/app_state.dart';
import '../../../../core/services/pdf_service.dart';
import '../../../../core/storage/database.dart';
import '../../../../core/utils/qr_signer.dart';

class QrDisplayScreen extends ConsumerWidget {
  const QrDisplayScreen({super.key, required this.lotId});

  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final user = ref.watch(appStateProvider);
    final lang = user.language;

    final lot = db.getMaterialById(lotId);
    final tx = db.getTransactionByLotId(lotId);
    final allRecyclers = db.getAllRecyclers();

    if (lot == null || tx == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(switch (lang) {
            'mr' => 'हस्तांतरण क्यूआर',
            'en' => 'Handover QR',
            _ => 'हस्तांतरण क्यूआर',
          }),
        ),
        body: Center(
          child: Text(switch (lang) {
            'mr' => 'माहिती उपलब्ध नाही.',
            'en' => 'No data available.',
            _ => 'डेटा उपलब्ध नहीं है।',
          }),
        ),
      );
    }

    final recycler = allRecyclers.firstWhere(
      (r) => r.recyclerId == tx.recyclerId,
      orElse: () => allRecyclers.first,
    );

    // Build authentic HMAC-SHA256 signed QR payload
    final rawPayload = QrSigner.buildPayload(
      txId: tx.txId,
      lotId: lot.lotId,
      collectorId: lot.collectorId,
      lat: lot.lat ?? user.lat,
      lon: lot.lon ?? user.lon,
      category: lot.category,
      subCategory: lot.subCategory,
      estWeightKg: lot.estWeightKg,
      quotedValueInr: tx.quotedValueInr,
      netOfferedPriceInr: tx.finalSettledInr,
      photoHash: lot.imageEdgeHash,
    );

    final signedQrBlob = QrSigner.sign(rawPayload);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          switch (lang) {
            'mr' => 'हस्तांतरण डिजिटल टोकन (QR)',
            'en' => 'Handover Verification QR',
            _ => 'हस्तांतरण डिजिटल टोकन (QR)',
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Minimalist Instructions Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_2, color: Color(0xFF059669), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        switch (lang) {
                          'mr' => 'हा क्यूआर कोड रिसायकलरच्या वजन काटा काउंटरवर दाखवा आणि लगेच रोख रक्कम मिळवा.',
                          'en' => 'Show this secure QR at the recycler weighbridge to receive instant cash.',
                          _ => 'यह क्यूआर कोड रीसाइक्लर के वजन कांटा काउंटर पर दिखाएं और तुरंत ₹${tx.finalSettledInr.toStringAsFixed(0)} नकद प्राप्त करें।',
                        },
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // QR Code Card (Clean Minimalist White)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: QrImageView(
                        data: signedQrBlob,
                        version: QrVersions.auto,
                        size: 210,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF059669),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tx.txId,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      switch (lang) {
                        'mr' => 'सुरक्षित HMAC-SHA256 डिजिटल टोकन • वैधता: २४ तास',
                        'en' => 'Cryptographic HMAC-SHA256 Token • Valid 24h',
                        _ => 'सुरक्षित HMAC-SHA256 डिजिटल टोकन • वैधता: २४ घंटे',
                      },
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Container(height: 1, color: const Color(0xFFF1F5F9)),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDetailCol(
                          title: switch (lang) {
                            'mr' => 'सामग्री',
                            'en' => 'Material',
                            _ => 'सामग्री',
                          },
                          val: lot.subCategory.split('(').first,
                        ),
                        _buildDetailCol(
                          title: switch (lang) {
                            'mr' => 'वजन',
                            'en' => 'Weight',
                            _ => 'वजन',
                          },
                          val: '${lot.estWeightKg.toStringAsFixed(1)} kg',
                        ),
                        _buildDetailCol(
                          title: switch (lang) {
                            'mr' => 'एकूण नकद',
                            'en' => 'Total Cash',
                            _ => 'कुल नकद',
                          },
                          val: '₹${tx.finalSettledInr.toStringAsFixed(0)}',
                          isGreen: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Recycler Info Pill (Clean Minimalist White)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.factory_outlined, color: Color(0xFF475569), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recycler.legalEntityName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'CPCB: ${recycler.cpcbRegNumber} • ${recycler.contactPhone}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Test Scan Simulation Button
              FilledButton(
                onPressed: () {
                  context.push(AppRoutes.handoverScan, extra: signedQrBlob);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.document_scanner_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      switch (lang) {
                        'mr' => 'रिसायकलर स्कॅन चाचणी करा →',
                        'en' => 'Test Recycler Scan Simulation →',
                        _ => 'रीसाइक्लर स्कैन का परीक्षण करें →',
                      },
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Print/Share PDF Manifest
              OutlinedButton(
                onPressed: () {
                  PdfReceiptService.generateAndPrintReceipt(
                    tx: tx,
                    lot: lot,
                    recycler: recycler,
                    collectorName: user.name,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF059669), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      switch (lang) {
                        'mr' => 'CPCB फॉर्म-६ पावती डाउनलोड करा',
                        'en' => 'Download CPCB Form-6 Receipt',
                        _ => 'CPCB फॉर्म-6 रसीद डाउनलोड करें',
                      },
                      style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 13),
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

  Widget _buildDetailCol({required String title, required String val, bool isGreen = false}) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Text(
          val,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isGreen ? const Color(0xFF059669) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
