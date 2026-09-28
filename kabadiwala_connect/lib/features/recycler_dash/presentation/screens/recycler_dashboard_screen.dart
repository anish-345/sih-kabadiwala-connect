import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/network/network_state.dart';
import '../../../../core/providers/app_state.dart';
import '../../../../core/services/pdf_service.dart';
import '../../../../core/storage/database.dart';
import '../../../../core/storage/models.dart';
import '../../../../core/widgets/offline_banner.dart';

class RecyclerDashboardScreen extends ConsumerWidget {
  const RecyclerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final user = ref.watch(appStateProvider);
    final netState = ref.watch(networkStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('अधिकृत रिसाइक्लर पोर्टल (CPCB Desk)'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          const NetworkStatusPill(),
          IconButton(
            tooltip: 'भूमिका बदलें (Switch Role)',
            icon: const Icon(Icons.switch_account_outlined),
            onPressed: () => context.go(AppRoutes.role),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<TransactionsData>>(
          stream: db.watchTransactions(),
          builder: (context, snapshot) {
            final transactions = snapshot.data ?? [];
            double totalWeight = 0;
            double totalPayout = 0;
            int verifiedLots = 0;

            for (final tx in transactions) {
              if (tx.txLifecycleState == 'SETTLED') {
                totalWeight += tx.weightKg;
                totalPayout += tx.finalSettledInr;
                verifiedLots++;
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const OfflineSyncBanner(),
                  const SizedBox(height: 12),

                  // Facility Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'E-Incarnation Recycling Pvt Ltd',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'CPCB Certified',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'CPCB Reg: CPCB/EWR/MH/2023/048 • MIDC Bhosari Facility, Pune',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatTile('कुल आवक', '${totalWeight.toStringAsFixed(1)} kg', Icons.scale),
                            _buildStatTile('सत्यापित लॉट', '$verifiedLots लॉट', Icons.inventory_2),
                            _buildStatTile('वितरित नकद', '₹${totalPayout.toStringAsFixed(0)}', Icons.payments),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Primary Scan Action
                  FilledButton.icon(
                    onPressed: () => context.push(AppRoutes.handoverScan),
                    icon: const Icon(Icons.qr_code_scanner, size: 24),
                    label: const Text(
                      'नया लॉट स्कैन करें (Scan Collector Lot) →',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sync Status / Outbox Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            netState.pendingOutboxCount == 0 ? Icons.cloud_done : Icons.cloud_upload,
                            color: netState.pendingOutboxCount == 0 ? Colors.green : Colors.orange,
                            size: 32,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  netState.pendingOutboxCount == 0
                                      ? 'CPCB व JNARDDC ऑडिट सिंक पूर्ण'
                                      : '${netState.pendingOutboxCount} रिकॉर्ड्स सिंक के लिए लंबित',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  netState.effectiveOnline
                                      ? 'ऑनलाइन मोड सक्रिय • पृष्ठभूमि सिंक चालू'
                                      : 'ऑफ़लाइन मोड (लोकल SQLite सुरक्षित)',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          if (netState.pendingOutboxCount > 0)
                            TextButton(
                              onPressed: () => ref.read(networkStateProvider.notifier).triggerSync(),
                              child: const Text('अभी सिंक करें', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Recent Handovers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'हाल ही में प्राप्त ई-कचरा लॉट (Verified Handovers):',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Text(
                        'Form-6 Manifests',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (transactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(child: Text('कोई हस्तांतरण नहीं हुआ है।')),
                    )
                  else
                    ...transactions.take(5).map((tx) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE3F2FD),
                            child: Icon(Icons.check, color: Color(0xFF1565C0)),
                          ),
                          title: Text('${tx.txId} • ${tx.weightKg.toStringAsFixed(1)} kg'),
                          subtitle: Text('भुगतान: ₹${tx.finalSettledInr.toStringAsFixed(0)} नकद • ${tx.settlementMode}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF1565C0)),
                            tooltip: 'CPCB रसीद प्रिंट करें',
                            onPressed: () {
                              final lot = db.getMaterialById(tx.lotId);
                              final allR = db.getAllRecyclers();
                              final rec = allR.firstWhere((r) => r.recyclerId == tx.recyclerId, orElse: () => allR.first);
                              if (lot != null) {
                                PdfReceiptService.generateAndPrintReceipt(
                                  tx: tx,
                                  lot: lot,
                                  recycler: rec,
                                  collectorName: user.name,
                                );
                              }
                            },
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatTile(String title, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1565C0)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}
