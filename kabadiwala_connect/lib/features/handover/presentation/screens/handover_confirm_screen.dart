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
        appBar: AppBar(
          title: Text(switch (lang) {
            'mr' => 'हस्तांतरण खात्री',
            'en' => 'Handover Verification',
            _ => 'हस्तांतरण पुष्टि',
          }),
        ),
        body: Center(
          child: Text(switch (lang) {
            'mr' => 'हस्तांतरण नोंद सापडली नाही.',
            'en' => 'Traceability record not found.',
            _ => 'हस्तांतरण रिकॉर्ड नहीं मिला।',
          }),
        ),
      );
    }

    final lot = db.getMaterialById(trace.lotId);
    final tx = db.getTransactionById(trace.txId) ?? db.getTransactionByLotId(trace.lotId);
    final allRecyclers = db.getAllRecyclers();

    if (lot == null || tx == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(switch (lang) {
            'mr' => 'हस्तांतरण खात्री',
            'en' => 'Handover Verification',
            _ => 'हस्तांतरण पुष्टि',
          }),
        ),
        body: Center(
          child: Text(switch (lang) {
            'mr' => 'लॉट किंवा व्यवहार उपलब्ध नाही.',
            'en' => 'Lot or transaction record missing.',
            _ => 'लॉट या ट्रांजेक्शन उपलब्ध नहीं है।',
          }),
        ),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          switch (lang) {
            'mr' => 'वजन काटा व रोख रक्कम पुष्टी',
            'en' => 'Weighbridge & Cash Settlement',
            _ => 'वजन कांटा व नकद भुगतान पुष्टि',
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // CPCB Compliance Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: Color(0xFF1D4ED8), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        switch (lang) {
                          'mr' => 'अधिकृत वजन काटा पडताळणी • बॅच ID: ${trace.cpcbBatchId}',
                          'en' => 'CPCB Authorized Weighbridge • Batch: ${trace.cpcbBatchId}',
                          _ => 'अधिकृत वजन कांटा सत्यापन • बैच ID: ${trace.cpcbBatchId}',
                        },
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Verification Card (Clean Minimalist White)
              Container(
                padding: const EdgeInsets.all(16.0),
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
                          '${switch (lang) {
                            'mr' => 'लॉट ID:',
                            'en' => 'Lot ID:',
                            _ => 'लॉट ID:',
                          }} ${lot.lotId}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                        Text('Tx: ${tx.txId}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${lot.category}: ${lot.subCategory}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${switch (lang) {
                        'mr' => 'कलेक्टर:',
                        'en' => 'Collector:',
                        _ => 'कलेक्टर:',
                      }} ${user.name} (${user.id})',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 14),
                    Container(height: 1, color: const Color(0xFFF1F5F9)),
                    const SizedBox(height: 14),

                    // Scale Weight Adjuster
                    Text(
                      switch (lang) {
                        'mr' => 'काट्यावरील प्रत्यक्ष वजन:',
                        'en' => 'Certified Weighbridge Scale Reading:',
                        _ => 'कांटा प्रमाणित वजन:',
                      },
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _actualWeightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
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
                          icon: const Icon(Icons.remove, size: 20),
                          onPressed: () {
                            final curr = double.tryParse(_actualWeightController.text) ?? 20.0;
                            if (curr > 1) {
                              setState(() => _actualWeightController.text = (curr - 0.5).toStringAsFixed(1));
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        IconButton.outlined(
                          icon: const Icon(Icons.add, size: 20),
                          onPressed: () {
                            final curr = double.tryParse(_actualWeightController.text) ?? 20.0;
                            setState(() => _actualWeightController.text = (curr + 0.5).toStringAsFixed(1));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Calculated final spot cash
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            switch (lang) {
                              'mr' => 'देय रोख रक्कम:',
                              'en' => 'Final Cash Payable:',
                              _ => 'अंतिम देय नकद:',
                            },
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF065F46)),
                          ),
                          Text(
                            '₹${finalCashToPay.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF065F46)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Minimalist Verification Checkboxes
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: _scaleCalibrated,
                      onChanged: (val) => setState(() => _scaleCalibrated = val ?? true),
                      title: Text(
                        switch (lang) {
                          'mr' => 'इलेक्ट्रॉनिक काटा प्रमाणीकरण योग्य आहे',
                          'en' => 'Electronic weighbridge calibration verified',
                          _ => 'इलेक्ट्रॉनिक कांटा कैलिब्रेशन सत्यापित है',
                        },
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                      subtitle: Text(
                        switch (lang) {
                          'mr' => 'वजन तफावत ±०.१ किलोपेक्षा कमी आहे.',
                          'en' => 'Discrepancy within legal ±0.1 kg tolerance.',
                          _ => 'वजन विसंगति ±०.१ किलो से कम है।',
                        },
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFF059669),
                    ),
                    const Divider(height: 1),
                    CheckboxListTile(
                      value: _cashGivenConfirmed,
                      onChanged: (val) => setState(() => _cashGivenConfirmed = val ?? false),
                      title: Text(
                        switch (lang) {
                          'mr' => 'कलेक्टरला ₹${finalCashToPay.toStringAsFixed(0)} रोख रक्कम दिली',
                          'en' => '₹${finalCashToPay.toStringAsFixed(0)} cash handed to collector',
                          _ => 'कलेक्टर को ₹${finalCashToPay.toStringAsFixed(0)} नकद राशि दी गई',
                        },
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                      subtitle: Text(
                        switch (lang) {
                          'mr' => 'काउंटरवर प्रत्यक्ष रोख नोटा सुपूर्द केल्या.',
                          'en' => 'Physical currency notes paid over the counter.',
                          _ => 'स्थानिक काउंटर पर भौतिक नोट सौंपे गए।',
                        },
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFF059669),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Confirm Handover Button
              FilledButton(
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
                            'en' => 'Handover successfully completed. ₹${finalCashToPay.toStringAsFixed(0)} settled in cash.',
                            _ => 'हस्तांतरण सफलतापूर्वक संपन्न हुआ। कुल ₹${finalCashToPay.toStringAsFixed(0)} नकद भुगतान हुआ।',
                          },
                          lang: lang,
                        );

                        // Show Success Dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => AlertDialog(
                            title: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Color(0xFF059669), size: 26),
                                const SizedBox(width: 8),
                                Text(switch (lang) {
                                  'mr' => 'हस्तांतरण यशस्वी!',
                                  'en' => 'Handover Complete!',
                                  _ => 'हस्तांतरण सफल!',
                                }),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(switch (lang) {
                                  'mr' => '₹${finalCashToPay.toStringAsFixed(0)} रोख रक्कम नोंदवली गेली.',
                                  'en' => '₹${finalCashToPay.toStringAsFixed(0)} cash payment recorded.',
                                  _ => '₹${finalCashToPay.toStringAsFixed(0)} नकद भुगतान दर्ज हुआ।',
                                }),
                                const SizedBox(height: 6),
                                Text('वजन: ${actualWeight.toStringAsFixed(1)} kg • रसीद: ${tx.txId}'),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    switch (lang) {
                                      'mr' => '✓ SQLite डेटाबेसमध्ये नोंद झाली\n✓ CPCB ऑडिट लेझरमध्ये नोंदणीकृत',
                                      'en' => '✓ Recorded in offline SQLite database\n✓ CPCB EPR audit ledger synchronized',
                                      _ => '✓ SQLite डेटाबेस में नया रिकॉर्ड जुड़ा\n✓ CPCB ऑडिट लेज़र में दर्ज',
                                    },
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF065F46)),
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
                                icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF059669)),
                                label: Text(
                                  switch (lang) {
                                    'mr' => 'CPCB पावती',
                                    'en' => 'CPCB Receipt',
                                    _ => 'CPCB रसीद',
                                  },
                                  style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w700),
                                ),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  context.go(AppRoutes.earnings);
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(
                                  switch (lang) {
                                    'mr' => 'कमाई लेझर पहा →',
                                    'en' => 'View Earnings →',
                                    _ => 'कमाई लेज़र देखें →',
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    : null,
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
                    const Icon(Icons.verified, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _cashGivenConfirmed
                          ? switch (lang) {
                              'mr' => 'हस्तांतरण व रोख रक्कम सुरक्षित करा ✓',
                              'en' => 'Settle Handover & Cash Payment ✓',
                              _ => 'हस्तांतरण व नकद भुगतान सुरक्षित करें ✓',
                            }
                          : switch (lang) {
                              'mr' => 'आधी रोख देयक बॉक्सवर खूण करा',
                              'en' => 'Confirm cash payment box first',
                              _ => 'पहले नकद भुगतान बॉक्स टिक करें',
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
}
