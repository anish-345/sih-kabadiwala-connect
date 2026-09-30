import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/providers/app_state.dart';
import '../../../../core/services/pdf_service.dart';
import '../../../../core/storage/database.dart';
import '../../../../core/storage/models.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  String _filter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final user = ref.watch(appStateProvider);
    final lang = user.language;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: StreamBuilder<List<TransactionsData>>(
          stream: db.watchTransactions(),
          builder: (context, snapshot) {
            final transactions = snapshot.data ?? [];

            // Calculate aggregate metrics
            double totalEarnings = 0;
            double totalKg = 0;
            int settledCount = 0;

            for (final tx in transactions) {
              if (tx.txLifecycleState == 'SETTLED') {
                totalEarnings += tx.finalSettledInr;
                totalKg += tx.weightKg;
                settledCount++;
              }
            }

            final filteredList = _filter == 'SETTLED'
                ? transactions.where((t) => t.txLifecycleState == 'SETTLED').toList()
                : _filter == 'PENDING'
                    ? transactions.where((t) => t.txLifecycleState != 'SETTLED').toList()
                    : transactions;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Minimalist Summary Card (Clean White with hairline border & subtle emerald accents)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: AppColors.accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        user.displayName,
                                        style: const TextStyle(
                                          color: AppColors.ink,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.accentBorder),
                                    ),
                                    child: Text(
                                      switch (lang) {
                                        'mr' => '१००% रोख लेझर',
                                        'en' => '100% Cash Ledger',
                                        _ => '१००% नकद लेज़र',
                                      },
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.accentMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                switch (lang) {
                                  'mr' => 'एकूण प्राप्त रोख रक्कम:',
                                  'en' => 'Total Settled Cash:',
                                  _ => 'कुल प्राप्त नकद राशि:',
                                },
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${totalEarnings.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 1,
                                color: AppColors.lineSoft,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatCol(
                                    label: switch (lang) {
                                      'mr' => 'संकलित वजन',
                                      'en' => 'Collected Weight',
                                      _ => 'संकलित वजन',
                                    },
                                    val: '${totalKg.toStringAsFixed(1)} kg',
                                  ),
                                  _buildStatCol(
                                    label: switch (lang) {
                                      'mr' => 'पूर्ण लॉट',
                                      'en' => 'Settled Lots',
                                      _ => 'पूर्ण लॉट',
                                    },
                                    val: switch (lang) {
                                      'mr' => '$settledCount लॉट',
                                      'en' => '$settledCount Lots',
                                      _ => '$settledCount लॉट',
                                    },
                                  ),
                                  _buildStatCol(
                                    label: switch (lang) {
                                      'mr' => 'EPR बोनस हिस्सा',
                                      'en' => 'EPR Credit Share',
                                      _ => 'EPR बोनस हिस्सा',
                                    },
                                    val: '₹${(totalEarnings * 0.14).toStringAsFixed(0)}',
                                    isHighlight: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Unit Economics Explainer Card (PS 26229 Requirement)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calculate_outlined, color: Color(0xFF059669), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    switch (lang) {
                                      'mr' => 'युनिट इकॉनॉमिक्स: थेट निव्वळ नफा',
                                      'en' => 'Unit Economics: Your Direct Net Gain',
                                      _ => 'यूनिट इकोनॉमिक्स: सीधा नकद लाभ',
                                    },
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                switch (lang) {
                                  'mr' =>
                                    'सूत्र: (अधिकृत गेट दर − स्थानिक दलाल दर) × एकूण किलो = अतिरिक्त नफा.\n'
                                    'कलेक्टर शुल्क: ₹0.00 (प्लॅटफॉर्म कबाड़ी बांधवांसाठी 100% मोफत आहे, 2% सुविधा शुल्क रिसायकलर देतो).',
                                  'en' =>
                                    'Formula: (Official Gate Rate − Middleman Rate) × Total kg = Net Cash Bonus.\n'
                                    'Collector Fee: ₹0.00 (Platform is 100% free for scrap collectors; 2% fee paid by authorized recyclers).',
                                  _ =>
                                    'सूत्र: (सरकारी गेट भाव − लोकल दलाल भाव) × कुल किलो = अतिरिक्त नकद बचत\n'
                                    'कलेक्टर शुल्क: ₹0.00 (प्लेटफ़ॉर्म कबाड़ी भाइयों के लिए 100% मुफ़्त है, 2% सुविधा शुल्क रीसाइक्लर देता है)।',
                                },
                                style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Filter Chips (Clean Minimalist Segmented Pills)
                        Row(
                          children: [
                            _buildFilterChip(
                              key: 'ALL',
                              label: switch (lang) {
                                'mr' => 'सर्व (${transactions.length})',
                                'en' => 'All (${transactions.length})',
                                _ => 'सभी (${transactions.length})',
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              key: 'SETTLED',
                              label: switch (lang) {
                                'mr' => 'रोख प्राप्त ($settledCount)',
                                'en' => 'Settled ($settledCount)',
                                _ => 'नकद प्राप्त ($settledCount)',
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              key: 'PENDING',
                              label: switch (lang) {
                                'mr' => 'प्रलंबित (${transactions.length - settledCount})',
                                'en' => 'Pending (${transactions.length - settledCount})',
                                _ => 'लंबित (${transactions.length - settledCount})',
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Transactions List
                if (filteredList.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                        child: Text(
                          switch (lang) {
                            'mr' => 'कोणतीही हस्तांतरण नोंद उपलब्ध नाही.',
                            'en' => 'No transaction records yet.',
                            _ => 'कोई हस्तांतरण रिकॉर्ड उपलब्ध नहीं है।',
                          },
                          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final tx = filteredList[index];
                          return _buildTxCard(tx, db, user.name, lang);
                        },
                        childCount: filteredList.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCol({required String label, required String val, bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 3),
        Text(
          val,
          style: TextStyle(
            color: isHighlight ? const Color(0xFF059669) : const Color(0xFF0F172A),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({required String key, required String label}) {
    final isSelected = _filter == key;
    return GestureDetector(
      onTap: () => setState(() => _filter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.line,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.muted,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTxCard(TransactionsData tx, AppDatabase db, String collectorName, String lang) {
    final isSettled = tx.txLifecycleState == 'SETTLED';
    final dateStr = DateTime.fromMillisecondsSinceEpoch(tx.createdAt).toLocal().toString().split(' ')[0];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tx.txId,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSettled ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isSettled ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A)),
                ),
                child: Text(
                  isSettled
                      ? switch (lang) {
                          'mr' => '✓ रोख रक्कम जमा',
                          'en' => '✓ Cash Settled',
                          _ => '✓ नकद भुगतान संपन्न',
                        }
                      : switch (lang) {
                          'mr' => 'पडताळणी प्रलंबित',
                          'en' => 'Pending Verification',
                          _ => 'सत्यापन प्रतीक्षारत',
                        },
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSettled ? const Color(0xFF065F46) : const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${tx.category ?? "E-Waste"} • ${tx.weightKg.toStringAsFixed(1)} kg • $dateStr',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          if (tx.recyclerName != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.business_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    tx.recyclerName!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    switch (lang) {
                      'mr' => 'जमा रक्कम',
                      'en' => 'Settled Amount',
                      _ => 'भुगतान राशि',
                    },
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '₹${tx.finalSettledInr.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {
                  final lot = db.getMaterialById(tx.lotId);
                  final allR = db.getAllRecyclers();
                  final recycler = allR.firstWhere(
                    (r) => r.recyclerId == tx.recyclerId,
                    orElse: () => allR.first,
                  );
                  if (lot != null) {
                    PdfReceiptService.generateAndPrintReceipt(
                      tx: tx,
                      lot: lot,
                      recycler: recycler,
                      collectorName: collectorName,
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: Color(0xFF059669)),
                label: Text(
                  switch (lang) {
                    'mr' => 'CPCB पावती',
                    'en' => 'CPCB Receipt',
                    _ => 'CPCB रसीद',
                  },
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  side: const BorderSide(color: Color(0xFFA7F3D0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
