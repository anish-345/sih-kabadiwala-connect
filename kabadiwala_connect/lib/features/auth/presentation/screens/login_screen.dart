import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/app_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController(text: '98221 44021');

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appStateProvider);
    final lang = user.language;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF7),
      appBar: AppBar(
        title: Text(
          switch (lang) {
            'mr' => 'लॉगिन / ओळख प्रमाणीकरण',
            'en' => 'Login / Verification',
            _ => 'लॉगिन / सत्यापन',
          },
        ),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: Color(0xFF2E7D32), size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            switch (lang) {
                              'mr' => 'ओटीपी किंवा पासवर्डची गरज नाही',
                              'en' => 'No Complex Passwords Needed',
                              _ => 'सरल मोबाइल सत्यापन',
                            },
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B5E20)),
                          ),
                          Text(
                            switch (lang) {
                              'mr' => 'असंगठित कामगारांसाठी त्वरित १-क्लिक सुरक्षित प्रवेश.',
                              'en' => 'Designed for informal workers with instant secure local session.',
                              _ => 'अनौपचारिक कामगारों के लिए सरल 1-क्लिक सुरक्षित प्रवेश।',
                            },
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                switch (lang) {
                  'mr' => 'आपला मोबाईल नंबर टाका',
                  'en' => 'Enter Mobile Number',
                  _ => 'अपना मोबाइल नंबर दर्ज करें',
                },
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Text(
                      '+91',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              FilledButton(
                onPressed: () {
                  ref.read(appStateProvider.notifier).setPhone('+91 ${_phoneController.text.trim()}');
                  context.push(AppRoutes.otp, extra: _phoneController.text.trim());
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  switch (lang) {
                    'mr' => 'ओटीपी मिळवा →',
                    'en' => 'Get Verification Code →',
                    _ => 'ओटीपी प्राप्त करें →',
                  },
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 32),
              const Divider(thickness: 1),
              const SizedBox(height: 12),

              // Demo evaluation profiles for Hackathon Judges
              Text(
                switch (lang) {
                  'mr' => 'हॅकाथॉन परीक्षकांसाठी चाचणी प्रोफाईल्स (Demo Profiles):',
                  'en' => 'Judge Evaluation Quick-Login Profiles:',
                  _ => 'हैकथॉन जजों के लिए 1-क्लिक डेमो प्रोफाइल्स:',
                },
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),

              _buildDemoProfileTile(
                name: 'रमेश शिंदे (Ramesh Shinde)',
                roleSubtitle: 'कबाड़ीवाला • नाना पेठ स्क्रैप मार्केट (Pune)',
                phone: '98221 44021',
                onTap: () {
                  _phoneController.text = '98221 44021';
                  ref.read(appStateProvider.notifier).setRole('collector');
                  context.go(AppRoutes.scanner);
                },
              ),
              const SizedBox(height: 8),

              _buildDemoProfileTile(
                name: 'सुशीला बाई जाधव (Sushila Bai)',
                roleSubtitle: 'माइक्रो-एग्रीगेटर • पिंपरी-चिंचवड (PCMC)',
                phone: '94220 58190',
                onTap: () {
                  _phoneController.text = '94220 58190';
                  ref.read(appStateProvider.notifier).setRole('collector');
                  context.go(AppRoutes.scanner);
                },
              ),
              const SizedBox(height: 8),

              _buildDemoProfileTile(
                name: 'विक्रम देशमुख (Recycler Desk)',
                roleSubtitle: 'E-Incarnation Recycling • MIDC Bhosari',
                phone: '98220 14890',
                isRecycler: true,
                onTap: () {
                  _phoneController.text = '98220 14890';
                  ref.read(appStateProvider.notifier).setRole('recycler');
                  context.go(AppRoutes.recyclerDash);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoProfileTile({
    required String name,
    required String roleSubtitle,
    required String phone,
    required VoidCallback onTap,
    bool isRecycler = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isRecycler ? Colors.blue.shade300 : Colors.green.shade300),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isRecycler ? Colors.blue.shade100 : Colors.green.shade100,
              radius: 18,
              child: Icon(
                isRecycler ? Icons.factory : Icons.person,
                color: isRecycler ? Colors.blue.shade900 : Colors.green.shade900,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(roleSubtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isRecycler ? Colors.blue.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'लॉगिन करें →',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isRecycler ? Colors.blue.shade800 : Colors.green.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
