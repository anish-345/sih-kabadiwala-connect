import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/app_state.dart';
import '../../../../core/storage/database.dart';
import '../../../../core/storage/models.dart';

class LotDetailScreen extends ConsumerStatefulWidget {
  const LotDetailScreen({super.key, required this.lotId});

  final String lotId;

  @override
  ConsumerState<LotDetailScreen> createState() => _LotDetailScreenState();
}

class _LotDetailScreenState extends ConsumerState<LotDetailScreen> {
  String? _selectedRecyclerId;
  String _settlementMode = 'CASH';

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final user = ref.watch(appStateProvider);
    final lang = user.language;

    final lot = db.getMaterialById(widget.lotId);
    final allRecyclers = db.getAllRecyclers();

    if (lot == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('लॉट विवरण')),
        body: const Center(child: Text('लॉट डेटा नहीं मिला।')),
      );
    }

    // Default select first recycler if none selected
    if (_selectedRecyclerId == null && allRecyclers.isNotEmpty) {
      _selectedRecyclerId = allRecyclers.first.recyclerId;
    }

    final selectedRecycler = allRecyclers.firstWhere(
      (r) => r.recyclerId == _selectedRecyclerId,
      orElse: () => allRecyclers.first,
    );

    final finalValuation = lot.estValuationInr * selectedRecycler.priceMultiplier;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),
      appBar: AppBar(
        title: Text(
          switch (lang) {
            'mr' => 'लॉट तपशील व रिसायकलर निवड',
            'en' => 'Lot Details & Recycler Match',
            _ => 'लॉट विवरण व रिसाइक्लर मिलान',
          },
        ),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Lot Overview Card
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              lot.lotId,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              lot.conditionGrade,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${lot.category}: ${lot.subCategory}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'प्रमाणित वजन: ${lot.estWeightKg.toStringAsFixed(1)} kg',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                          Text(
                            'अनुमानित देय: ₹${finalValuation.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Ranked Recycler Matching Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    switch (lang) {
                      'mr' => 'अधिकृत रिसायकलर्स क्रमवारी (Ranked Matches):',
                      'en' => 'Ranked Authorized Recyclers:',
                      _ => 'अधिकृत रिसाइक्लर वरीयता क्रम (Ranked Matches):',
                    },
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'CPCB Valid',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Recyclers List
              ...allRecyclers.map((r) => _buildRecyclerTile(r, lot, lang)),

              const SizedBox(height: 20),

              // Settlement Mode Choice Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        switch (lang) {
                          'mr' => 'पैसे स्वीकारण्याची पद्धत (Settlement Mode):',
                          'en' => 'Payment Mode at Gate:',
                          _ => 'भुगतान प्राप्ति का माध्यम (Settlement Mode):',
                        },
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      RadioListTile<String>(
                        value: 'CASH',
                        groupValue: _settlementMode,
                        title: const Text('तुरंत नकद (Spot Cash at Scale)', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('तौल होते ही रिसाइक्लर वजन कांटा काउंटर पर नकद देगा।', style: TextStyle(fontSize: 12)),
                        activeColor: const Color(0xFF2E7D32),
                        onChanged: (val) => setState(() => _settlementMode = val!),
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        value: 'UPI',
                        groupValue: _settlementMode,
                        title: const Text('यूपीआई / तुरंत बैंक खाता (UPI / IMPS)', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('स्कैन होते ही बैंक खाते में ट्रांसफर।', style: TextStyle(fontSize: 12)),
                        activeColor: const Color(0xFF2E7D32),
                        onChanged: (val) => setState(() => _settlementMode = val!),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Generate QR Button
              FilledButton.icon(
                onPressed: () {
                  final now = DateTime.now().millisecondsSinceEpoch;
                  final txId = 'TX-PUN-2026-${const Uuid().v4().substring(0, 6).toUpperCase()}';

                  // Upsert Transaction in SQLite
                  final tx = TransactionsData(
                    txId: txId,
                    lotId: lot.lotId,
                    quotedValueInr: finalValuation,
                    finalSettledInr: finalValuation,
                    settlementMode: _settlementMode,
                    txLifecycleState: 'QUOTED',
                    recyclerId: selectedRecycler.recyclerId,
                    recyclerName: selectedRecycler.legalEntityName,
                    category: lot.category,
                    weightKg: lot.estWeightKg,
                    quoteTimestamp: now,
                    createdAt: now,
                  );

                  db.upsertTransaction(tx);

                  // Add Outbox sync item
                  db.addOutbox(OutboxData(
                    id: const Uuid().v4(),
                    entityType: 'TRANSACTION_RECORD',
                    entityId: txId,
                    payloadJson: '',
                    status: 'PENDING',
                    createdAt: now,
                  ));

                  // Navigate to QR Screen
                  context.push('/lot/${lot.lotId}/qr');
                },
                icon: const Icon(Icons.qr_code_2, size: 24),
                label: Text(
                  switch (lang) {
                    'mr' => 'हस्तांतरण क्यूआर कोड तयार करा →',
                    'en' => 'Generate Handover QR Code →',
                    _ => 'हस्तांतरण क्यूआर कोड बनाएं →',
                  },
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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

  Widget _buildRecyclerTile(RecyclerData r, MaterialsData lot, String lang) {
    final isSelected = _selectedRecyclerId == r.recyclerId;
    final bonusText = r.priceMultiplier > 1.0 ? '+${((r.priceMultiplier - 1.0) * 100).round()}% बोनस' : 'मानक भाव';

    return InkWell(
      onTap: () => setState(() => _selectedRecyclerId = r.recyclerId),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<String>(
              value: r.recyclerId,
              groupValue: _selectedRecyclerId,
              activeColor: const Color(0xFF2E7D32),
              onChanged: (val) => setState(() => _selectedRecyclerId = val),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          r.legalEntityName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF1B5E20) : Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          bonusText,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CPCB: ${r.cpcbRegNumber} • वैधता: ${r.validUntil}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                      Text(' ${r.distanceKm.toStringAsFixed(1)} किमी दूर • ${r.facilityAddress.split(',').first}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                      const Spacer(),
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      Text(' ${r.rating.toStringAsFixed(1)} (${r.totalHandovers}+ लॉट)',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: r.features.take(2).map((f) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(f, style: TextStyle(fontSize: 10, color: Colors.grey.shade800)),
                      );
                    }).toList(),
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
