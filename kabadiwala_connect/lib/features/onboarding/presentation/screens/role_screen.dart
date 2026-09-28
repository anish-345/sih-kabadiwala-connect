import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/app_state.dart';

class RoleScreen extends ConsumerStatefulWidget {
  const RoleScreen({super.key});

  @override
  ConsumerState<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends ConsumerState<RoleScreen> {
  String _selectedRole = 'collector';

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(appStateProvider);
    final lang = userProfile.language;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF7),
      appBar: AppBar(
        title: Text(
          switch (lang) {
            'mr' => 'आपली भूमिका निवडा',
            'en' => 'Select Your Role',
            _ => 'अपनी भूमिका चुनें',
          },
        ),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                switch (lang) {
                  'mr' => 'तुम्ही अॅप कसे वापरू इच्छिता?',
                  'en' => 'How would you like to use this app?',
                  _ => 'आप इस ऐप का उपयोग किस रूप में करना चाहते हैं?',
                },
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                switch (lang) {
                  'mr' => 'तुमच्या भूमिकेनुसार योग्य सुविधा उपलब्ध होतील.',
                  'en' => 'Features tailored to your operational requirements.',
                  _ => 'आपकी भूमिका के अनुसार उपयुक्त सुविधाएं उपलब्ध होंगी।',
                },
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // Role Card 1: Collector
              _buildRoleCard(
                roleKey: 'collector',
                icon: Icons.electric_rickshaw,
                title: switch (lang) {
                  'mr' => 'कबाडीवाला / भंगार संकलक',
                  'en' => 'Scrap Collector / Aggregator',
                  _ => 'कबाड़ीवाला / स्क्रैप संकलनकर्ता',
                },
                subtitle: switch (lang) {
                  'mr' => 'रोजचे अचूक भाव पाहा, लॉट तयार करा आणि थेट अधिकृत रिसायकलर्सकडून लगेच रोख रक्कम मिळवा.',
                  'en' => 'Check daily verified rates, create scrap lots, and receive instant cash from authorized recyclers.',
                  _ => 'दैनिक प्रामाणिक भाव देखें, लॉट बनाएं और अधिकृत रिसाइक्लर से तुरंत नकद प्राप्त करें।',
                },
                badgeText: switch (lang) {
                  'mr' => 'विनामूल्य • ०% फी',
                  'en' => '100% Free • 0% Fee',
                  _ => 'निःशुल्क • 0% शुल्क',
                },
                badgeColor: Colors.green.shade800,
              ),

              const SizedBox(height: 16),

              // Role Card 2: Recycler
              _buildRoleCard(
                roleKey: 'recycler',
                icon: Icons.factory,
                title: switch (lang) {
                  'mr' => 'अधिकृत रिसायकलर (CPCB नोंदणीकृत)',
                  'en' => 'Authorized Recycler (CPCB Registered)',
                  _ => 'अधिकृत रिसाइक्लर (CPCB पंजीकृत)',
                },
                subtitle: switch (lang) {
                  'mr' => 'संकलकांकडून थेट डिजिटल लॉट स्कॅन करा, वजन तपासा आणि कायदेशीर EPR ऑडिट पावती जारी करा.',
                  'en' => 'Scan incoming collector lots, verify scale weights, and issue digital CPCB Form-6 manifests.',
                  _ => 'संकलनकर्ताओं से डिजिटल लॉट स्कैन करें, वजन सत्यापित करें और CPCB ऑडिट रसीद जारी करें।',
                },
                badgeText: 'EPR Rules 2022 Verified',
                badgeColor: Colors.blue.shade800,
              ),

              const Spacer(),

              // Next Button
              FilledButton(
                onPressed: () {
                  ref.read(appStateProvider.notifier).setRole(_selectedRole);
                  if (_selectedRole == 'recycler') {
                    context.go(AppRoutes.recyclerDash);
                  } else {
                    context.push(AppRoutes.walkthrough);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  switch (lang) {
                    'mr' => 'प्रारंभ करा →',
                    'en' => 'Proceed →',
                    _ => 'शुरू करें →',
                  },
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String roleKey,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
  }) {
    final isSelected = _selectedRole == roleKey;

    return InkWell(
      onTap: () => setState(() => _selectedRole = roleKey),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black87,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF1B5E20) : Colors.black87,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 22),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                    ),
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
