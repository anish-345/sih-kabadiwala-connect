import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_state.dart';
import '../../../../core/services/voice_service.dart';

class SafetyScreen extends ConsumerWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider);
    final voiceService = ref.watch(voiceServiceProvider);
    final lang = user.language;

    final guides = [
      (
        icon: Icons.battery_alert,
        iconColor: Colors.deepOrange,
        title: switch (lang) {
          'mr' => '१. लिथियम-आयन बॅटरी: आगीचा मोठा धोका',
          'en' => '1. Lithium-Ion Battery: Fire & Explosion Risk',
          _ => '1. लिथियम बैटरी: आग व विस्फोट का खतरा',
        },
        dangerBadge: 'अत्यंत घातक • CRITICAL HAZARD',
        dangerColor: Colors.red.shade800,
        dos: [
          'बॅटरीवर टेप लावून वाळूच्या बादलीत वेगळी ठेवा (Store in dry sand).',
          'फक्त अधिकृत रिसायकलरला सुरक्षित स्वरूपात सुपूर्द करा.',
        ],
        donts: [
          'बॅटरी कधीही कापू नका, हातोड्याने फोडू नका (Never puncture with pliers).',
          'उन्हात किंवा आगीजवळ ठेवू नका — क्षणात स्फोट होऊ शकतो.',
        ],
        voiceText: 'सावधान! लिथियम बैटरी को कभी न फोड़ें और न ही काटें। इसमें आग लगने और विस्फोट का भयंकर खतरा होता है। इसे सूखी रेत की बाल्टी में सुरक्षित रखें।',
      ),
      (
        icon: Icons.tv_off,
        iconColor: Colors.indigo,
        title: switch (lang) {
          'mr' => '२. जुने सीआरटी टीव्ही ग्लास: विषारी शिसे (Lead)',
          'en' => '2. CRT Monitor Glass: Toxic Lead Hazard',
          _ => '2. सीआरटी मॉनिटर: विषारी सीसा (Lead Oxide)',
        },
        dangerBadge: 'विषारी रासायनिक धोका • TOXIC',
        dangerColor: Colors.purple.shade800,
        dos: [
          'हातामध्ये जाड हातमोजे (Gloves) व डोळ्यांवर गॉगल वापरा.',
          'ग्लास अखंड ठेवून सुरक्षितपणे हाताळा.',
        ],
        donts: [
          'काच मोकळ्या जागेत हातोड्याने फोडू नका (Never smash openly).',
          'फुफ्फुसात शिशाची विषारी धूळ गेल्याने कायमचे आजारपण येऊ शकते.',
        ],
        voiceText: 'सीआरटी मॉनिटर के कांच में जहरीला लेड ऑक्साइड होता है। कांच को कभी न फोड़ें। हमेशा मोटे दस्ताने और चश्मा पहनकर काम करें।',
      ),
      (
        icon: Icons.local_fire_department,
        iconColor: Colors.red,
        title: switch (lang) {
          'mr' => '३. तारा जाळणे पूर्णपणे बेकायदेशीर व घातक',
          'en' => '3. Open Cable Burning: Deadly Dioxin Fumes',
          _ => '3. तारों को जलाना सख्त मना व दंडनीय अपराध',
        },
        dangerBadge: 'कर्करोगजनक धूर • CANCER RISK',
        dangerColor: Colors.red.shade900,
        dos: [
          'इन्सुलेटेड तांब्याची वायर थेट अधिकृत रिसायकलरला ₹४६०/किलो भावाने विका.',
          'यांत्रिक स्ट्रिपिंग मशीनचा वापर करा.',
        ],
        donts: [
          'रात्री शेतात किंवा पत्र्यावर वायर जाळू नका (Never burn PVC wires).',
          'या धुरातून निघणारा डायऑक्सिन गॅस कर्करोग (Cancer) निर्माण करतो.',
        ],
        voiceText: 'तारों को आग लगाकर तांबा निकालना कानूनी अपराध है और इसके धुएं से कैंसर होता है। पूरी केबल अधिकृत रिसाइक्लर को ₹460 प्रति किलो में सीधे बेचें।',
      ),
      (
        icon: Icons.science,
        iconColor: Colors.teal,
        title: switch (lang) {
          'mr' => '४. ई-कचरा प्लास्टिक (BFRs युक्त)',
          'en' => '4. E-Plastics: Toxic Flame Retardants',
          _ => '4. ई-कचरा प्लास्टिक: जहरीले रसायन',
        },
        dangerBadge: 'पर्यावरणीय धोका • TOXIC PLASTIC',
        dangerColor: Colors.amber.shade900,
        dos: [
          'काळ्या व राखाडी इलेक्ट्रॉनिक बॉडी प्लास्टिकला कोरडे ठेवा.',
          'कॅटेगरीनुसार सॉर्ट करून रिसायकलरला द्या.',
        ],
        donts: [
          'प्लास्टिक गरम करून घरगुती विरघळवू नका (Do not melt).',
          'पाण्यात किंवा नाल्यात वाहून देऊ नका.',
        ],
        voiceText: 'इलेक्ट्रॉनिक प्लास्टिक में ब्रोमिनेटेड रसायन होते हैं। इसे कभी आग में न पिघलाएं।',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: guides.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.health_and_safety, color: Colors.red.shade900, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        switch (lang) {
                          'mr' => 'आपले आरोग्य हीच खरी संपत्ती! भंगार हाताळताना हे ४ नियम पाळा.',
                          'en' => 'Protect your health! Follow these 4 vital safety rules for scrap handling.',
                          _ => 'स्वास्थ्य ही सबसे बड़ी पूंजी है! ई-कचरा संभालते समय इन 4 नियमों का पालन करें।',
                        },
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              );
            }

            final guide = guides[index - 1];

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: guide.iconColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(guide.icon, color: guide.iconColor, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(guide.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: guide.dangerColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  guide.dangerBadge,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: guide.dangerColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up, color: Color(0xFF2E7D32)),
                          tooltip: 'नियम बोलकर सुनें',
                          onPressed: () => voiceService.speakSafety(guide.title, guide.voiceText, lang),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // DOs
                    const Text('✓ काय करावे (DOs):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20))),
                    const SizedBox(height: 4),
                    ...guide.dos.map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(bottom: 3.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                            Expanded(child: Text(d, style: const TextStyle(fontSize: 12, height: 1.3))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // DONTs
                    const Text('✗ काय टाळावे (DONTs):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                    const SizedBox(height: 4),
                    ...guide.donts.map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(bottom: 3.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                            Expanded(child: Text(d, style: const TextStyle(fontSize: 12, height: 1.3))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
