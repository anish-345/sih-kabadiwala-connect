import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/app_state.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _pinController = TextEditingController(text: '1234');

  @override
  void dispose() {
    _pinController.dispose();
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
            'mr' => 'ओटीपी सत्यापन',
            'en' => 'PIN Verification',
            _ => 'ओटीपी सत्यापन',
          },
        ),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                switch (lang) {
                  'mr' => '${widget.phone} वर पाठवलेला ४-अंकी पिन टाका',
                  'en' => 'Enter 4-digit verification code sent to ${widget.phone}',
                  _ => '${widget.phone} पर भेजा गया 4-अंकीय पिन दर्ज करें',
                },
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Text(
                  'डेमो पिन: 1234 (मूल्यांकन के लिए पहले से भरा हुआ)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown),
                ),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 4,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 16),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              FilledButton(
                onPressed: () {
                  if (user.role == 'recycler') {
                    context.go(AppRoutes.recyclerDash);
                  } else {
                    context.go(AppRoutes.scanner);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  switch (lang) {
                    'mr' => 'सत्यापित करा व पुढे जा ✓',
                    'en' => 'Verify & Continue ✓',
                    _ => 'सत्यापित करें और आगे बढ़ें ✓',
                  },
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
