import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_theme.dart';
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
        appBar: AppBar(
          title: Text(switch (lang) {
            'mr' => 'लॉट तपशील',
            'en' => 'Lot Details',
            _ => 'लॉट विवरण',
          }),
        ),
        body: Center(
          child: Text(switch (lang) {
            'mr' => 'लॉट सापडला नाही.',
            'en' => 'Lot record not found.',
            _ => 'लॉट डेटा नहीं मिला।',
          }),
        ),
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
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          switch (lang) {
            'mr' => 'लॉट तपशील व रिसायकलर निवड',
            'en' => 'Lot & Recycler Match',
            _ => 'लॉट व रीसाइक्लर चयन',
          },
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1, color: AppColors.line),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Minimalist Lot Overview Card
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(color: AppColors.accentBorder),
                          ),
                          child: Text(
                            lot.lotId,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentMuted,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Text(
                            lot.conditionGrade,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${lot.category}: ${lot.subCategory}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          switch (lang) {
                            'mr' => 'वजन: ${lot.estWeightKg.toStringAsFixed(1)} kg',
                            'en' => 'Weight: ${lot.estWeightKg.toStringAsFixed(1)} kg',
                            _ => 'वजन: ${lot.estWeightKg.toStringAsFixed(1)} कि.ग्रा.',
                          },
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        Text(
                          '₹${finalValuation.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.accent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Ranked Recycler Matching Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    switch (lang) {
                      'mr' => 'अधिकृत रिसायकलर्स (Ranked):',
                      'en' => 'Authorized Recycler Match:',
                      _ => 'अधिकृत रीसाइक्लर वरीयता क्रम:',
                    },
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.infoSoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.infoBorder),
                    ),
                    child: const Text(
                      'CPCB Valid',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.info),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Recyclers List
              ...allRecyclers.map((r) => _buildRecyclerTile(r, lot, lang)),

              const SizedBox(height: 18),

              // Settlement Mode Choice Card (Clean Minimalist White)
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
                    Text(
                      switch (lang) {
                        'mr' => 'पैसे स्वीकारण्याची पद्धत:',
                        'en' => 'Payment Mode at Gate:',
                        _ => 'भुगतान प्राप्ति का माध्यम:',
                      },
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),
                    _buildSettlementOption(
                      mode: 'CASH',
                      title: switch (lang) {
                        'mr' => 'काट्यावर थेट रोख रक्कम',
                        'en' => 'Spot Cash at Scale Counter',
                        _ => 'तुरंत नकद भुगतान',
                      },
                      subtitle: switch (lang) {
                        'mr' => 'वजन होताच रिसायकलर काउंटरवर लगेच रोख पैसे देईल.',
                        'en' => 'Instant cash at the weighbridge counter upon handover.',
                        _ => 'तौल होते ही रीसाइक्लर वजन कांटा काउंटर पर नकद देगा।',
                      },
                      icon: Icons.payments_outlined,
                    ),
                    const SizedBox(height: 8),
                    _buildSettlementOption(
                      mode: 'UPI',
                      title: switch (lang) {
                        'mr' => 'यूपीआय / थेट बँक खाते',
                        'en' => 'UPI / Direct Bank Transfer',
                        _ => 'यूपीआई / तुरंत बैंक खाता',
                      },
                      subtitle: switch (lang) {
                        'mr' => 'स्कॅन पूर्ण होताच बँक खात्यात त्वरित ट्रान्सफर.',
                        'en' => 'Direct transfer to linked bank account upon verification.',
                        _ => 'स्कैन होते ही बैंक खाते में सीधे ट्रांसफर।',
                      },
                      icon: Icons.account_balance_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Generate QR Button
              FilledButton(
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
                    payloadJson: jsonEncode(tx.toMap()),
                    status: 'PENDING',
                    createdAt: now,
                  ));

                  // Navigate to QR Screen
                  context.push('/lot/${lot.lotId}/qr');
                },
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
                    const Icon(Icons.qr_code_2, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      switch (lang) {
                        'mr' => 'हस्तांतरण क्यूआर कोड तयार करा →',
                        'en' => 'Generate Handover QR Code →',
                        _ => 'हस्तांतरण क्यूआर कोड बनाएं →',
                      },
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

  Widget _buildSettlementOption({
    required String mode,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _settlementMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _settlementMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                  width: isSelected ? 5.0 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(icon, color: isSelected ? const Color(0xFF059669) : const Color(0xFF64748B), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isSelected ? const Color(0xFF065F46) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecyclerTile(RecyclerData r, MaterialsData lot, String lang) {
    final isSelected = _selectedRecyclerId == r.recyclerId;
    final bonusText = r.priceMultiplier > 1.0
        ? switch (lang) {
            'mr' => '+${((r.priceMultiplier - 1.0) * 100).round()}% बोनस',
            'en' => '+${((r.priceMultiplier - 1.0) * 100).round()}% Bonus',
            _ => '+${((r.priceMultiplier - 1.0) * 100).round()}% बोनस',
          }
        : switch (lang) {
            'mr' => 'मानक दर',
            'en' => 'Standard Rate',
            _ => 'मानक भाव',
          };

    return GestureDetector(
      onTap: () => setState(() => _selectedRecyclerId = r.recyclerId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 2, right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                  width: isSelected ? 5.0 : 1.5,
                ),
              ),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? const Color(0xFF065F46) : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFA7F3D0) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          bonusText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? const Color(0xFF065F46) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CPCB: ${r.cpcbRegNumber} • ${switch (lang) {
                      'mr' => 'वैधता:',
                      'en' => 'Valid until:',
                      _ => 'वैधता:',
                    }} ${r.validUntil}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                      Text(
                        ' ${r.distanceKm.toStringAsFixed(1)} ${switch (lang) {
                          'mr' => 'किमी दूर',
                          'en' => 'km away',
                          _ => 'किमी दूर',
                        }} • ${r.facilityAddress.split(',').first}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                      ),
                      const Spacer(),
                      const Icon(Icons.star, size: 13, color: Color(0xFFF59E0B)),
                      Text(
                        ' ${r.rating.toStringAsFixed(1)} (${r.totalHandovers}+ ${switch (lang) {
                          'mr' => 'लॉट',
                          'en' => 'lots',
                          _ => 'लॉट',
                        }})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                    ],
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
