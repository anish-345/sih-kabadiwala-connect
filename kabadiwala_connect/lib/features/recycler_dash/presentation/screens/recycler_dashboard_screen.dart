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
    final lang = user.language;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          switch (lang) {
            'mr' => 'अधिकृत रिसायकलर पोर्टल',
            'en' => 'Authorized Recycler Portal',
            _ => 'अधिकृत रीसाइक्लर पोर्टल',
          },
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
        ),
        actions: [
          const NetworkStatusPill(),
          IconButton(
            tooltip: switch (lang) {
              'mr' => 'भूमिका बदला',
              'en' => 'Switch Role',
              _ => 'भूमिका बदलें',
            },
            icon: const Icon(Icons.switch_account_outlined, color: Color(0xFF475569)),
            onPressed: () => context.go(AppRoutes.role),
          ),
          const SizedBox(width: 8),
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

                  // Facility Info Card (Clean Minimalist White)
                  Container(
                    padding: const EdgeInsets.all(16),
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
                            const Expanded(
                              child: Text(
                                'E-Incarnation Recycling Pvt Ltd',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: const Text(
                                'CPCB Certified',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'CPCB Reg: CPCB/EWR/MH/2023/048 • MIDC Bhosari, Pune',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 14),
                        Container(height: 1, color: const Color(0xFFF1F5F9)),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatTile(
                              title: switch (lang) {
                                'mr' => 'एकूण वजन',
                                'en' => 'Total Weight',
                                _ => 'कुल वजन',
                              },
                              val: '${totalWeight.toStringAsFixed(1)} kg',
                              icon: Icons.scale_outlined,
                            ),
                            _buildStatTile(
                              title: switch (lang) {
                                'mr' => 'सत्यापित लॉट',
                                'en' => 'Verified Lots',
                                _ => 'सत्यापित लॉट',
                              },
                              val: '$verifiedLots',
                              icon: Icons.inventory_2_outlined,
                            ),
                            _buildStatTile(
                              title: switch (lang) {
                                'mr' => 'वितरित रोख',
                                'en' => 'Cash Settled',
                                _ => 'वितरित नकद',
                              },
                              val: '₹${totalPayout.toStringAsFixed(0)}',
                              icon: Icons.payments_outlined,
                              isGreen: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Primary Scan Action
                  FilledButton(
                    onPressed: () => context.push(AppRoutes.handoverScan),
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
                        const Icon(Icons.qr_code_scanner, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          switch (lang) {
                            'mr' => 'नवीन लॉट स्कॅन करा →',
                            'en' => 'Scan Collector Lot →',
                            _ => 'नया लॉट स्कैन करें →',
                          },
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sync Status Card (Clean Minimalist White)
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          netState.pendingOutboxCount == 0 ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined,
                          color: netState.pendingOutboxCount == 0 ? const Color(0xFF059669) : const Color(0xFFD97706),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                netState.pendingOutboxCount == 0
                                    ? switch (lang) {
                                        'mr' => 'CPCB व JNARDDC ऑडिट सिंक पूर्ण',
                                        'en' => 'CPCB & JNARDDC Audit Synced',
                                        _ => 'CPCB व JNARDDC ऑडिट सिंक पूर्ण',
                                      }
                                    : switch (lang) {
                                        'mr' => '${netState.pendingOutboxCount} नोंदी सिंकसाठी प्रलंबित',
                                        'en' => '${netState.pendingOutboxCount} records pending sync',
                                        _ => '${netState.pendingOutboxCount} रिकॉर्ड्स सिंक के लिए लंबित',
                                      },
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                netState.effectiveOnline
                                    ? switch (lang) {
                                        'mr' => 'ऑनलाइन मोड सक्रिय • बॅकग्राउंड सिंक चालू',
                                        'en' => 'Online mode active • background sync on',
                                        _ => 'ऑनलाइन मोड सक्रिय • पृष्ठभूमि सिंक चालू',
                                      }
                                    : switch (lang) {
                                        'mr' => 'ऑफलाइन मोड (स्थानिक SQLite मध्ये सुरक्षित)',
                                        'en' => 'Offline mode (secured in local SQLite)',
                                        _ => 'ऑफ़लाइन मोड (लोकल SQLite सुरक्षित)',
                                      },
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        if (netState.pendingOutboxCount > 0)
                          TextButton(
                            onPressed: () => ref.read(networkStateProvider.notifier).triggerSync(),
                            child: Text(
                              switch (lang) {
                                'mr' => 'आता सिंक करा',
                                'en' => 'Sync Now',
                                _ => 'अभी सिंक करें',
                              },
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Recent Handovers Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        switch (lang) {
                          'mr' => 'नुकतीच प्राप्त झालेली लॉट्स:',
                          'en' => 'Recent Verified Handovers:',
                          _ => 'हाल ही में प्राप्त ई-कचरा लॉट:',
                        },
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                      const Text(
                        'Form-6 Manifests',
                        style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          switch (lang) {
                            'mr' => 'कोणतेही हस्तांतरण झाले नाही.',
                            'en' => 'No verified handovers yet.',
                            _ => 'कोई हस्तांतरण नहीं हुआ है।',
                          },
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ...transactions.take(5).map((tx) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFECFDF5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Color(0xFF059669), size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${tx.txId} • ${tx.weightKg.toStringAsFixed(1)} kg',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${tx.finalSettledInr.toStringAsFixed(0)} • ${tx.settlementMode}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF059669), size: 20),
                              tooltip: 'CPCB Receipt',
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
                          ],
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

  Widget _buildStatTile({required String title, required String val, required IconData icon, bool isGreen = false}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: isGreen ? const Color(0xFF059669) : const Color(0xFF475569)),
        const SizedBox(height: 4),
        Text(
          val,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isGreen ? const Color(0xFF059669) : const Color(0xFF0F172A),
          ),
        ),
        Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ],
    );
  }
}
