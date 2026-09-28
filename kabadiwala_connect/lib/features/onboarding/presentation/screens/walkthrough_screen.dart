import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/app_state.dart';

class WalkthroughScreen extends ConsumerStatefulWidget {
  const WalkthroughScreen({super.key});

  @override
  ConsumerState<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends ConsumerState<WalkthroughScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appStateProvider);
    final lang = user.language;

    final steps = [
      (
        icon: Icons.camera_alt,
        title: switch (lang) {
          'mr' => '१. भंगाराचा फोटो व वजन नोंदवा',
          'en' => '1. Capture Photo & Weight',
          _ => '1. ई-कचरे की फोटो व वजन दर्ज करें',
        },
        desc: switch (lang) {
          'mr' => 'मदरबोर्ड, केबल्स किंवा बॅटरीचा फोटो काढा किंवा वर्ग निवडा आणि अंदाजे वजन टाका.',
          'en' => 'Take a scrap photo or pick from categories (PCB, Cables, Batteries) and enter weight.',
          _ => 'मदरबोर्ड, केबल या बैटरी की फोटो लें या श्रेणी चुनें और वजन दर्ज करें।',
        },
        tag: 'आसान इंटरफ़ेस • Easy To Use',
      ),
      (
        icon: Icons.currency_rupee,
        title: switch (lang) {
          'mr' => '२. सरकारी भाव व रिसायकलर निवडा',
          'en' => '2. Compare Rates & Choose Recycler',
          _ => '2. सरकारी भाव व नजदीकी रिसाइक्लर चुनें',
        },
        desc: switch (lang) {
          'mr' => 'स्थानिक दलालापेक्षा +४०% ते +७०% जास्तीचा अधिकृत गेट भाव आणि मोफत पिकअप सुविधा मिळवा.',
          'en' => 'Get +40% to +70% higher formal gate rates plus CPCB EPR incentive bonuses with doorstep pickup.',
          _ => 'स्थानीय दलालों से +40% से +70% अधिक गेट भाव और CPCB ईपीआर बोनस सीधे प्राप्त करें।',
        },
        tag: 'पारदर्शी भाव • Fair Pricing',
      ),
      (
        icon: Icons.qr_code_2,
        title: switch (lang) {
          'mr' => '३. क्यूआर दाखवा आणि रोख पैसे घ्या',
          'en' => '3. Show QR Code & Receive Instant Cash',
          _ => '3. क्यूआर कोड दिखाएं और तुरंत नकद लें',
        },
        desc: switch (lang) {
          'mr' => 'रिसायकलर तुमच्या फोनवरील डिजिटल क्यूआर स्कॅन करेल आणि तो जागेवर लगेच रोख पैसे देईल.',
          'en' => 'Authorized recycler scans your secure QR, verifies the scale weight, and hands over cash instantly.',
          _ => 'रिसाइक्लर आपके फोन का क्यूआर कोड स्कैन करेगा और तराजू वजन की पुष्टि कर तुरंत नकद भुगतान करेगा।',
        },
        tag: 'तुरंत नकद • Instant Cash',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF7),
      appBar: AppBar(
        title: Text(
          switch (lang) {
            'mr' => 'अॅप कसे कार्य करते?',
            'en' => 'How It Works',
            _ => 'ऐप कैसे काम करता है?',
          },
        ),
        backgroundColor: const Color(0xFF2E7D32),
        actions: [
          TextButton(
            onPressed: () => context.go(AppRoutes.scanner),
            child: const Text(
              'छोड़ें (Skip)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: steps.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    final step = steps[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF2E7D32), width: 3),
                          ),
                          child: Icon(step.icon, size: 70, color: const Color(0xFF1B5E20)),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Text(
                            step.tag,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          step.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          step.desc,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.4),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Page Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  steps.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.push(AppRoutes.login),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        switch (lang) {
                          'mr' => 'लॉगिन करा',
                          'en' => 'Login (Optional)',
                          _ => 'लॉगिन (वैकल्पिक)',
                        },
                        style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        if (_currentPage < steps.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          context.go(AppRoutes.scanner);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _currentPage < steps.length - 1
                            ? (lang == 'mr' ? 'पुढे >' : 'आगे बढ़ें >')
                            : (lang == 'mr' ? 'थेट सुरू करा ✓' : 'शुरू करें ✓'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
