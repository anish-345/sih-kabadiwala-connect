import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      backgroundColor: const Color(0xFFF4F8F4),
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
                // Top Summary Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
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
                                    user.name,
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade400,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      '१००% नकद लेज़र',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text('कुल प्राप्त नकद राशि (Total Settled Cash):', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                '₹${totalEarnings.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Divider(color: Colors.white24, height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatCol('संकलित वजन', '${totalKg.toStringAsFixed(1)} kg'),
                                  _buildStatCol('पूर्ण हस्तांतरण', '$settledCount लॉट'),
                                  _buildStatCol('EPR बोनस हिस्सा', '₹${(totalEarnings * 0.14).toStringAsFixed(0)}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Unit Economics Explainer Card (PS 26229 Requirement)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calculate_outlined, color: Color(0xFF1B5E20), size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    switch (lang) {
                                      'mr' => 'युनिट इकॉनॉमिक्स: तुमचा थेट निव्वळ नफा',
                                      'en' => 'Unit Economics: Your Direct Net Gain',
                                      _ => 'यूनिट इकोनॉमिक्स: कबाड़ीवाला सीधा लाभ',
                                    },
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'सूत्र: (सरकारी गेट भाव − लोकल दलाल भाव) × कुल किलो = अतिरिक्त नकद बचत\n'
                                'कलेक्टर शुल्क: ₹0.00 (प्लेटफ़ॉर्म 100% मुफ़्त है, 2% सुविधा शुल्क रीसाइक्लर देता है)।',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Filter Chips
                        Row(
                          children: [
                            _buildFilterChip('ALL', 'सभी (${transactions.length})'),
                            const SizedBox(width: 8),
                            _buildFilterChip('SETTLED', 'नकद प्राप्त ($settledCount)'),
                            const SizedBox(width: 8),
                            _buildFilterChip('PENDING', 'लंबित (${transactions.length - settledCount})'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Transactions List
                if (filteredList.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                        child: Text('कोई हस्तांतरण रिकॉर्ड उपलब्ध नहीं है।'),
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
                          return _buildTxCard(tx, db, user.name);
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

  Widget _buildStatCol(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF2E7D32),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _filter = key);
      },
    );
  }

  Widget _buildTxCard(TransactionsData tx, AppDatabase db, String collectorName) {
    final isSettled = tx.txLifecycleState == 'SETTLED';
    final dateStr = DateTime.fromMillisecondsSinceEpoch(tx.createdAt).toLocal().toString().split(' ')[0];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tx.txId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSettled ? Colors.green.shade50 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSettled ? Colors.green.shade300 : Colors.amber.shade300),
                  ),
                  child: Text(
                    isSettled ? '✓ नकद भुगतान संपन्न' : 'प्रतीक्षारत (Quoted)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSettled ? const Color(0xFF1B5E20) : Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${tx.category ?? "E-Waste"} • ${tx.weightKg.toStringAsFixed(1)} kg • $dateStr',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (tx.recyclerName != null) ...[
              const SizedBox(height: 4),
              Text(
                'रिसाइक्लर: ${tx.recyclerName}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
            ],
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('भुगतान राशि:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      '₹${tx.finalSettledInr.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                    ),
                  ],
                ),
                TextButton.icon(
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
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('CPCB रसीद', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
