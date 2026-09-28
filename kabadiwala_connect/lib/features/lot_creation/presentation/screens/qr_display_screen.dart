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
        appBar: AppBar(title: const Text('हस्तांतरण क्यूआर')),
        body: const Center(child: Text('डेटा उपलब्ध नहीं है।')),
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
      lat: lot.lat ?? 18.5204,
      lon: lot.lon ?? 73.8567,
      category: lot.category,
      subCategory: lot.subCategory,
      estWeightKg: lot.estWeightKg,
      quotedValueInr: tx.quotedValueInr,
      netOfferedPriceInr: tx.finalSettledInr,
      photoHash: lot.imageEdgeHash,
    );

    final signedQrBlob = QrSigner.sign(rawPayload);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),
      appBar: AppBar(
        title: Text(
          switch (lang) {
            'mr' => 'हस्तांतरण डिजिटल टोकन (QR)',
            'en' => 'Handover Verification QR',
            _ => 'हस्तांतरण डिजिटल टोकन (QR)',
          },
        ),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instructions Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code, color: Color(0xFF1B5E20), size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        switch (lang) {
                          'mr' => 'हा क्यूआर कोड रिसायकलरच्या वजन काटा काउंटरवर दाखवा आणि लगेच रोख रक्कम मिळवा.',
                          'en' => 'Show this secure QR code at the recycler weighbridge to receive instant cash.',
                          _ => 'यह क्यूआर कोड रिसाइक्लर के वजन कांटा काउंटर पर दिखाएं और तुरंत ₹${tx.finalSettledInr.toStringAsFixed(0)} नकद प्राप्त करें।',
                        },
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // QR Code Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: QrImageView(
                          data: signedQrBlob,
                          version: QrVersions.auto,
                          size: 220,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF1B5E20),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tx.txId,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'सुरक्षित HMAC-SHA256 डिजिटल टोकन • वैधता: २४ घंटे',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailCol('सामग्री (Item)', lot.subCategory.split('(').first),
                          _buildDetailCol('वजन (Weight)', '${lot.estWeightKg.toStringAsFixed(1)} kg'),
                          _buildDetailCol('कुल नकद (Cash)', '₹${tx.finalSettledInr.toStringAsFixed(0)}', isGreen: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Recycler Info Pill
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.factory, color: Colors.blueGrey, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(recycler.legalEntityName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('CPCB: ${recycler.cpcbRegNumber} • फोन: ${recycler.contactPhone}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Test Scan Simulation Button (Crucial for live Hackathon demonstration)
              FilledButton.icon(
                onPressed: () {
                  // Direct simulation: navigate to recycler handover scanner with signed QR payload
                  context.push(AppRoutes.handoverScan, extra: signedQrBlob);
                },
                icon: const Icon(Icons.document_scanner, size: 20),
                label: const Text(
                  'रिसाइक्लर स्कैन का परीक्षण करें (Test Recycler Scan) →',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),

              // Print/Share PDF Manifest
              OutlinedButton.icon(
                onPressed: () {
                  PdfReceiptService.generateAndPrintReceipt(
                    tx: tx,
                    lot: lot,
                    recycler: recycler,
                    collectorName: user.name,
                  );
                },
                icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF2E7D32)),
                label: const Text(
                  'CPCB Form-6 रसीद डाउनलोड / प्रिंट करें',
                  style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCol(String title, String val, {bool isGreen = false}) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isGreen ? const Color(0xFF1B5E20) : Colors.black87,
          ),
        ),
      ],
    );
  }
}
