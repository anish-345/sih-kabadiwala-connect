import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/app_state.dart';
import '../../../../core/services/pdf_service.dart';
import '../../../../core/services/voice_service.dart';
import '../../../../core/storage/database.dart';
import '../../../../core/storage/models.dart';

class HandoverConfirmScreen extends ConsumerStatefulWidget {
  const HandoverConfirmScreen({super.key, required this.traceId});

  final String traceId;

  @override
  ConsumerState<HandoverConfirmScreen> createState() => _HandoverConfirmScreenState();
}

class _HandoverConfirmScreenState extends ConsumerState<HandoverConfirmScreen> {
  late TextEditingController _actualWeightController;
  bool _scaleCalibrated = true;
  bool _cashGivenConfirmed = false;
  bool _isSettling = false;

  @override
  void initState() {
    super.initState();
    _actualWeightController = TextEditingController(text: '20.0');
  }

  @override
  void dispose() {
    _actualWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final user = ref.watch(appStateProvider);
    final voiceService = ref.watch(voiceServiceProvider);
    final lang = user.language;

    final trace = db.getTraceabilityById(widget.traceId);
    if (trace == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('हस्तांतरण पुष्टि')),
        body: const Center(child: Text('हस्तांतरण रिकॉर्ड नहीं मिला।')),
      );
    }

    final lot = db.getMaterialById(trace.lotId);
    final tx = db.getTransactionById(trace.txId) ?? db.getTransactionByLotId(trace.lotId);
    final allRecyclers = db.getAllRecyclers();

    if (lot == null || tx == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('हस्तांतरण पुष्टि')),
        body: const Center(child: Text('लॉट या ट्रांजेक्शन उपलब्ध नहीं है।')),
      );
    }

    final recycler = allRecyclers.firstWhere(
      (r) => r.recyclerId == tx.recyclerId,
      orElse: () => allRecyclers.first,
    );

    final actualWeight = double.tryParse(_actualWeightController.text) ?? lot.estWeightKg;
    final ratePerKg = lot.estWeightKg > 0 ? (tx.finalSettledInr / lot.estWeightKg) : 190.0;
    final finalCashToPay = actualWeight * ratePerKg;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),
      appBar: AppBar(
        title: const Text('तौल व नकद भुगतान पुष्टि (Weighbridge Confirm)'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // CPCB Compliance Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: Color(0xFF1565C0), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'अधिकृत वजन कांटा सत्यापन • बैच ID: ${trace.cpcbBatchId}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Verification Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('लॉट ID: ${lot.lotId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Tx: ${tx.txId}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${lot.category}: ${lot.subCategory}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Text('कलेक्टर: ${user.name} (${user.id})', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      const Divider(height: 20),

                      // Scale Weight Adjuster
                      Text(
                        'कांटा प्रमाणित वजन (Certified Scale Weight):',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _actualWeightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                suffixText: 'kg',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.outlined(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              final curr = double.tryParse(_actualWeightController.text) ?? 20.0;
                              if (curr > 1) {
                                setState(() => _actualWeightController.text = (curr - 0.5).toStringAsFixed(1));
                              }
                            },
                          ),
                          const SizedBox(width: 4),
                          IconButton.outlined(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              final curr = double.tryParse(_actualWeightController.text) ?? 20.0;
                              setState(() => _actualWeightController.text = (curr + 0.5).toStringAsFixed(1));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Calculated final spot cash
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('अंतिम देय नकद (Final Cash):', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              '₹${finalCashToPay.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Recycler Checkboxes
              CheckboxListTile(
                value: _scaleCalibrated,
                onChanged: (val) => setState(() => _scaleCalibrated = val ?? true),
                title: const Text('इलेक्ट्रॉनिक कांटा कैलिब्रेशन सत्यापित है', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('वजन विसंगति ±०.१ किलो से कम है।', style: TextStyle(fontSize: 11)),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFF1565C0),
              ),
              CheckboxListTile(
                value: _cashGivenConfirmed,
                onChanged: (val) => setState(() => _cashGivenConfirmed = val ?? false),
                title: Text('कलेक्टर को ₹${finalCashToPay.toStringAsFixed(0)} नकद राशि दी गई', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('स्थानिक काउंटर पर भौतिक नोट सौंपे गए।', style: TextStyle(fontSize: 11)),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFF1B5E20),
              ),

              const SizedBox(height: 20),

              // Confirm Handover Button
              FilledButton.icon(
                onPressed: _cashGivenConfirmed && !_isSettling
                    ? () async {
                        setState(() => _isSettling = true);
                        final now = DateTime.now().millisecondsSinceEpoch;

                        // 1. Update Transaction to SETTLED
                        final settledTx = TransactionsData(
                          txId: tx.txId,
                          lotId: lot.lotId,
                          quotedValueInr: tx.quotedValueInr,
                          finalSettledInr: finalCashToPay,
                          settlementMode: tx.settlementMode,
                          txLifecycleState: 'SETTLED',
                          recyclerId: recycler.recyclerId,
                          recyclerName: recycler.legalEntityName,
                          category: lot.category,
                          weightKg: actualWeight,
                          quoteTimestamp: tx.quoteTimestamp,
                          settlementTs: now,
                          paymentReference: 'CASH-REC-SPOT-${now.toString().substring(8)}',
                          createdAt: tx.createdAt,
                        );
                        db.upsertTransaction(settledTx);

                        // 2. Update Traceability
                        db.insertTraceability(TraceabilityData(
                          traceId: trace.traceId,
                          lotId: trace.lotId,
                          txId: tx.txId,
                          handoverQrHash: trace.handoverQrHash,
                          edgeTimestamp: trace.edgeTimestamp,
                          handoverLat: trace.handoverLat,
                          handoverLon: trace.handoverLon,
                          verificationStatus: 'VERIFIED_OFFLINE',
                          recyclerSignature: 'SIG-REC-${recycler.cpcbRegNumber.hashCode}',
                          collectorSignature: 'SIG-COLL-${user.id}',
                          cpcbBatchId: trace.cpcbBatchId,
                          createdAt: trace.createdAt,
                        ));

                        // 3. Add to Outbox
                        db.addOutbox(OutboxData(
                          id: const Uuid().v4(),
                          entityType: 'CPCB_EPR_AUDIT_HANDOVER',
                          entityId: tx.txId,
                          payloadJson: '{"tx_id":"${tx.txId}","weight_kg":$actualWeight,"settled_inr":$finalCashToPay}',
                          status: 'PENDING',
                          createdAt: now,
                        ));

                        // Speak Vernacular Confirmation
                        voiceService.speak(
                          switch (lang) {
                            'mr' => 'हस्तांतरण यशस्वीरित्या पूर्ण झाले. एकूण रक्कम ₹${finalCashToPay.toStringAsFixed(0)} रोख प्राप्त झाली.',
                            'en' => 'Handover successfully completed. ₹${finalCashToPay.toStringAsFixed(0)} paid in cash.',
                            _ => 'हस्तांतरण सफलतापूर्वक संपन्न हुआ। कुल ₹${finalCashToPay.toStringAsFixed(0)} नकद भुगतान हुआ।',
                          },
                          lang: lang,
                        );

                        // Show Success Dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 28),
                                SizedBox(width: 8),
                                Text('हस्तांतरण सफल!'),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('₹${finalCashToPay.toStringAsFixed(0)} नकद भुगतान दर्ज हुआ।'),
                                const SizedBox(height: 6),
                                Text('वजन: ${actualWeight.toStringAsFixed(1)} kg • रसीद: ${tx.txId}'),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '✓ SQLite डेटाबेस में नया रिकॉर्ड जुड़ा\n✓ CPCB ऑडिट लेज़र में दर्ज',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF1B5E20)),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton.icon(
                                onPressed: () {
                                  PdfReceiptService.generateAndPrintReceipt(
                                    tx: settledTx,
                                    lot: lot,
                                    recycler: recycler,
                                    collectorName: user.name,
                                  );
                                },
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('CPCB रसीद प्रिंट करें'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  context.go(AppRoutes.earnings);
                                },
                                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                                child: const Text('कमाई लेज़र देखें →'),
                              ),
                            ],
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.verified, size: 22),
                label: Text(
                  _cashGivenConfirmed
                      ? 'हस्तांतरण व नकद भुगतान सुरक्षित करें ✓'
                      : 'पहले नकद भुगतान बॉक्स टिक करें',
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
}
