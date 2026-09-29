import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/app_state.dart';
import '../../../../core/services/voice_service.dart';
import '../../../../core/storage/database.dart';
import '../../../../core/storage/models.dart';

class PriceBoardScreen extends ConsumerStatefulWidget {
  const PriceBoardScreen({super.key});

  @override
  ConsumerState<PriceBoardScreen> createState() => _PriceBoardScreenState();
}

class _PriceBoardScreenState extends ConsumerState<PriceBoardScreen> {
  String _selectedCategory = 'ALL';

  List<({String key, String label})> _getCategories(String lang) {
    return [
      (
        key: 'ALL',
        label: switch (lang) {
          'mr' => 'सर्व',
          'en' => 'All',
          _ => 'सभी',
        },
      ),
      (
        key: 'PCB',
        label: switch (lang) {
          'mr' => 'मदरबोर्ड (PCB)',
          'en' => 'Motherboard (PCB)',
          _ => 'मदरबोर्ड (PCB)',
        },
      ),
      (
        key: 'Cables',
        label: switch (lang) {
          'mr' => 'केबल्स (Cables)',
          'en' => 'Cables',
          _ => 'केबल्स (Cables)',
        },
      ),
      (
        key: 'Batteries',
        label: switch (lang) {
          'mr' => 'बॅटरी (Batteries)',
          'en' => 'Batteries',
          _ => 'बैटरी (Batteries)',
        },
      ),
      (
        key: 'Displays',
        label: switch (lang) {
          'mr' => 'डिस्प्ले (Displays)',
          'en' => 'Displays',
          _ => 'डिस्प्ले (Displays)',
        },
      ),
      (
        key: 'Motors',
        label: switch (lang) {
          'mr' => 'मोटर्स / कोर (Motors)',
          'en' => 'Motors & Cores',
          _ => 'मोटर / कोर (Motors)',
        },
      ),
      (
        key: 'Plastics',
        label: switch (lang) {
          'mr' => 'प्लॅस्टिक (Plastics)',
          'en' => 'Plastics',
          _ => 'प्लास्टिक (Plastics)',
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final user = ref.watch(appStateProvider);
    final voiceService = ref.watch(voiceServiceProvider);
    final lang = user.language;
    final categories = _getCategories(lang);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Minimalist Header banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Icon(Icons.analytics_outlined, color: Color(0xFF059669), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          switch (lang) {
                            'mr' => 'पुणे आणि पिंपरी-चिंचवड अधिकृत दर',
                            'en' => 'Pune & PCMC Verified Recycler Rates',
                            _ => 'पुणे और पिंपरी-चिंचवड अधिकृत गेट भाव',
                          },
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'CPCB EPR Rules 2022 • JNARDDC Benchmark',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up_outlined, color: Color(0xFF059669), size: 24),
                    tooltip: switch (lang) {
                      'mr' => 'दर ऐका',
                      'en' => 'Listen to Rates',
                      _ => 'भाव बोलकर सुनें',
                    },
                    onPressed: () {
                      final all = db.getAllPrices();
                      if (all.isNotEmpty) {
                        voiceService.speakPrice(all.first, lang);
                      }
                    },
                  ),
                ],
              ),
            ),

            // Minimalist Category filter chips
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.white,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategory == cat.key;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF059669) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        cat.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(height: 1, color: const Color(0xFFE2E8F0)),

            // Live Prices Stream from SQLite
            Expanded(
              child: StreamBuilder<List<PriceFeedData>>(
                stream: db.watchPrices(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final prices = snapshot.data ?? [];
                  final filtered = _selectedCategory == 'ALL'
                      ? prices
                      : prices.where((p) => p.category == _selectedCategory).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        switch (lang) {
                          'mr' => 'कोणतेही भाव उपलब्ध नाहीत',
                          'en' => 'No rates found for this category',
                          _ => 'इस श्रेणी के लिए कोई भाव उपलब्ध नहीं हैं',
                        },
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildPriceCard(item, lang, voiceService);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(PriceFeedData item, String lang, VoiceService voiceService) {
    final surplusPercent = item.informalBaseRate > 0
        ? (((item.netOfferedPrice - item.informalBaseRate) / item.informalBaseRate) * 100).round()
        : 0;

    final isUp = item.trend == 'UP';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Top Row: Category badge + Sub-category name + Audio listen
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Text(
                        item.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.subCategory,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_outlined, color: Color(0xFF059669), size: 22),
                tooltip: switch (lang) {
                  'mr' => 'दर ऐका',
                  'en' => 'Listen Rate',
                  _ => 'भाव बोलकर सुनें',
                },
                onPressed: () => voiceService.speakPrice(item, lang),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Price Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    switch (lang) {
                      'mr' => 'एकूण अधिकृत दर:',
                      'en' => 'Net Formal Price:',
                      _ => 'कुल देय सरकारी भाव:',
                    },
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${item.netOfferedPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        switch (lang) {
                          'mr' => '/ किलो',
                          'en' => '/ kg',
                          _ => '/ कि.ग्रा.',
                        },
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // Surplus badge
              if (surplusPercent > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    switch (lang) {
                      'mr' => '+$surplusPercent% जादा',
                      'en' => '+$surplusPercent% More',
                      _ => '+$surplusPercent% अतिरिक्त',
                    },
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Rate Breakdown Pills (Minimalist subtle slate container)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniBreakdown(
                  label: switch (lang) {
                    'mr' => 'गेट दर',
                    'en' => 'Gate Rate',
                    _ => 'गेट भाव',
                  },
                  value: '₹${item.formalGateRate.toStringAsFixed(0)}',
                ),
                const Text('+', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                _buildMiniBreakdown(
                  label: switch (lang) {
                    'mr' => 'EPR बोनस',
                    'en' => 'EPR Credit',
                    _ => 'EPR बोनस',
                  },
                  value: '+₹${item.eprCreditShare.toStringAsFixed(0)}',
                ),
                const Text('+', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                _buildMiniBreakdown(
                  label: switch (lang) {
                    'mr' => 'NCMM खनिज',
                    'en' => 'NCMM Bonus',
                    _ => 'NCMM खनिज',
                  },
                  value: '+₹${item.ncmmIncentive.toStringAsFixed(0)}',
                ),
                const Text('vs', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                _buildMiniBreakdown(
                  label: switch (lang) {
                    'mr' => 'स्थानिक दलाल',
                    'en' => 'Middleman',
                    _ => 'लोकल दलाल',
                  },
                  value: '₹${item.informalBaseRate.toStringAsFixed(0)}',
                  isOld: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 7-day mini trend sparkline
          if (item.trendHistory.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: item.trendHistory
                                .asMap()
                                .entries
                                .map((e) => FlSpot(e.key.toDouble(), e.value))
                                .toList(),
                            isCurved: true,
                            color: isUp ? const Color(0xFF059669) : const Color(0xFFDC2626),
                            barWidth: 2.2,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: (isUp ? const Color(0xFF059669) : const Color(0xFFDC2626)).withValues(alpha: 0.08),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    Icon(
                      isUp ? Icons.trending_up : Icons.trending_down,
                      color: isUp ? const Color(0xFF059669) : const Color(0xFFDC2626),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.trendDeltaPercent >= 0 ? '+' : ''}${item.trendDeltaPercent}% ${switch (lang) {
                        'mr' => '(७ दिवस)',
                        'en' => '(7 days)',
                        _ => '(७ दिन)',
                      }}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isUp ? const Color(0xFF065F46) : const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 12),

          // Minimalist Bottom Action: Sell this material
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go(AppRoutes.scanner),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_shopping_cart, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    switch (lang) {
                      'mr' => 'हा माल विका (लॉट तयार करा) →',
                      'en' => 'Sell Material (Create Lot) →',
                      _ => 'माल बेचें (लॉट बनाएं) →',
                    },
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBreakdown({required String label, required String value, bool isOld = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isOld ? const Color(0xFFDC2626) : const Color(0xFF64748B),
            fontWeight: isOld ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isOld ? const Color(0xFF991B1B) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
