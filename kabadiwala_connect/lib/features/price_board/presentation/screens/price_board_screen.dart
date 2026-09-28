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

  final List<({String key, String label})> _categories = [
    (key: 'ALL', label: 'सभी (All)'),
    (key: 'PCB', label: 'मदरबोर्ड (PCB)'),
    (key: 'Cables', label: 'केबल्स (Cables)'),
    (key: 'Batteries', label: 'बैटरी (Batteries)'),
    (key: 'Displays', label: 'डिस्प्ले (Displays)'),
    (key: 'Motors', label: 'मोटर / कोर (Motors)'),
    (key: 'Plastics', label: 'प्लास्टिक (Plastics)'),
  ];

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final user = ref.watch(appStateProvider);
    final voiceService = ref.watch(voiceServiceProvider);
    final lang = user.language;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.analytics, color: Color(0xFF1B5E20), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          switch (lang) {
                            'mr' => 'पुणे / पिंपरी-चिंचवड अधिकृत भाव',
                            'en' => 'Pune & PCMC Verified Recycler Rates',
                            _ => 'पुणे / पिंपरी-चिंचवड अधिकृत गेट भाव',
                          },
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          'CPCB EPR Rules 2022 • JNARDDC Benchmark',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: Color(0xFF2E7D32), size: 26),
                    tooltip: 'भाव बोलकर सुनें (Listen All)',
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

            // Category filter chips
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: Colors.white,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat.key;
                  return ChoiceChip(
                    label: Text(cat.label),
                    selected: isSelected,
                    selectedColor: const Color(0xFF2E7D32),
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = cat.key);
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1, thickness: 1),

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
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category + Sub-category + Spoken Rate Icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subCategory,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Color(0xFF2E7D32), size: 24),
                  tooltip: 'बोलकर सुनें (Listen Rate)',
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
                        'mr' => 'निव्वळ अधिकृत भाव (Net Offered):',
                        'en' => 'Net Formal Price:',
                        _ => 'कुल देय सरकारी भाव:',
                      },
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '₹${item.netOfferedPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const Text(
                          ' / किलो (kg)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
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
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+$surplusPercent% अतिरिक्त',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Rate Breakdown Pills
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniBreakdown('गेट भाव', '₹${item.formalGateRate.toStringAsFixed(0)}'),
                  const Text('+', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  _buildMiniBreakdown('EPR बोनस', '+₹${item.eprCreditShare.toStringAsFixed(0)}'),
                  const Text('+', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  _buildMiniBreakdown('NCMM खनिज', '+₹${item.ncmmIncentive.toStringAsFixed(0)}'),
                  const Text('vs', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  _buildMiniBreakdown('लोकल दलाल', '₹${item.informalBaseRate.toStringAsFixed(0)}', isOld: true),
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
                      height: 36,
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
                              color: isUp ? Colors.green.shade700 : Colors.red.shade700,
                              barWidth: 2.5,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: (isUp ? Colors.green : Colors.red).withOpacity(0.12),
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
                        color: isUp ? Colors.green.shade700 : Colors.red.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.trendDeltaPercent >= 0 ? '+' : ''}${item.trendDeltaPercent}% (७ दिन)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isUp ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 12),

            // Bottom Action: Sell this material
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => context.go(AppRoutes.scanner),
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: Text(
                  switch (lang) {
                    'mr' => 'हा माल विका (Create Lot) →',
                    'en' => 'Sell This Material (Create Lot) →',
                    _ => 'इस भाव पर माल बेचें (लॉट बनाएं) →',
                  },
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade100,
                  foregroundColor: const Color(0xFF1B5E20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBreakdown(String label, String value, {bool isOld = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isOld ? Colors.red.shade700 : Colors.grey.shade700,
            fontWeight: isOld ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isOld ? Colors.red.shade900 : Colors.black87,
          ),
        ),
      ],
    );
  }
}
