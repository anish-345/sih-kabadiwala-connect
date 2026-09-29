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
        iconColor: const Color(0xFFDC2626),
        title: switch (lang) {
          'mr' => '१. लिथियम-आयन बॅटरी: आगीचा धोका',
          'en' => '1. Lithium-Ion Battery: Fire & Explosion Risk',
          _ => '1. लिथियम बैटरी: आग व विस्फोट का खतरा',
        },
        dangerBadge: switch (lang) {
          'mr' => 'अत्यंत घातक • CRITICAL HAZARD',
          'en' => 'CRITICAL HAZARD',
          _ => 'अत्यंत घातक • CRITICAL HAZARD',
        },
        dangerColor: const Color(0xFFDC2626),
        dos: switch (lang) {
          'mr' => [
            'बॅटरीवर टेप लावून वाळूच्या बादलीत वेगळी ठेवा.',
            'फक्त अधिकृत रिसायकलरला सुरक्षित स्वरूपात सुपूर्द करा.',
          ],
          'en' => [
            'Tape battery terminals and isolate in a dry sand container.',
            'Hand over directly to authorized recyclers without puncturing.',
          ],
          _ => [
            'बैटरी टर्मिनल्स पर टेप लगाकर सूखी रेत की बाल्टी में अलग रखें।',
            'केवल अधिकृत रीसाइक्लर को सुरक्षित रूप से सौंपें।',
          ],
        },
        donts: switch (lang) {
          'mr' => [
            'बॅटरी कधीही कापू नका किंवा हातोड्याने फोडू नका.',
            'उन्हात किंवा आगीजवळ ठेवू नका — क्षणात स्फोट होऊ शकतो.',
          ],
          'en' => [
            'Never crush, puncture, or open battery casings with tools.',
            'Never expose batteries to direct heat, open flames, or water.',
          ],
          _ => [
            'बैटरी को कभी भी हथौड़े से न तोड़ें और न ही काटें।',
            'धूप या आग के पास न रखें — तुरंत विस्फोट हो सकता है।',
          ],
        },
        voiceText: switch (lang) {
          'mr' => 'सावधान! लिथियम बॅटरी कधीही कापू नका किंवा फोडू नका. यात आगीचा मोठा धोका असतो.',
          'en' => 'Caution: Never puncture or crush lithium batteries. Always isolate them in dry sand.',
          _ => 'सावधान! लिथियम बैटरी को कभी न फोड़ें और न ही काटें। इसमें आग लगने और विस्फोट का खतरा होता है।',
        },
      ),
      (
        icon: Icons.tv_off,
        iconColor: const Color(0xFF4F46E5),
        title: switch (lang) {
          'mr' => '२. जुने सीआरटी टीव्ही ग्लास: विषारी शिसे (Lead)',
          'en' => '2. CRT Monitor Glass: Toxic Lead Hazard',
          _ => '2. सीआरटी मॉनिटर: विषैला सीसा (Lead Oxide)',
        },
        dangerBadge: switch (lang) {
          'mr' => 'विषारी रासायनिक धोका • TOXIC',
          'en' => 'TOXIC CHEMICAL HAZARD',
          _ => 'विषैला रासायनिक खतरा • TOXIC',
        },
        dangerColor: const Color(0xFF7C3AED),
        dos: switch (lang) {
          'mr' => [
            'हातामध्ये जाड हातमोजे व डोळ्यांवर गॉगल वापरा.',
            'ग्लास अखंड ठेवून सुरक्षितपणे हाताळा.',
          ],
          'en' => [
            'Wear heavy puncture-resistant gloves and safety goggles.',
            'Keep glass funnel and neck intact during transport.',
          ],
          _ => [
            'हाथों में मोटे दस्ताने और आंखों पर चश्मा पहनकर काम करें।',
            'कांच को बिना तोड़े सुरक्षित तरीके से संभालें।',
          ],
        },
        donts: switch (lang) {
          'mr' => [
            'काच मोकळ्या जागेत हातोड्याने फोडू नका.',
            'फुफ्फुसात शिशाची विषारी धूळ गेल्याने गंभीर आजार होऊ शकतात.',
          ],
          'en' => [
            'Never smash CRT glass in open yards or residential areas.',
            'Do not inhale fine glass phosphor powder — severe toxicity risk.',
          ],
          _ => [
            'कांच को खुले में हथौड़े से कभी न तोड़ें।',
            'फेफड़ों में सीसे की जहरीली धूल जाने से स्थायी बीमारी हो सकती है।',
          ],
        },
        voiceText: switch (lang) {
          'mr' => 'सीआरटी मॉनिटरच्या काचेमध्ये विषारी शिसे असते. काच कधीही फोडू नका.',
          'en' => 'CRT glass contains hazardous lead oxide. Never smash glass and always wear protection.',
          _ => 'सीआरटी मॉनिटर के कांच में जहरीला लेड ऑक्साइड होता है। कांच को कभी न फोड़ें।',
        },
      ),
      (
        icon: Icons.local_fire_department,
        iconColor: const Color(0xFFEA580C),
        title: switch (lang) {
          'mr' => '३. वायर जाळणे पूर्णपणे बेकायदेशीर व घातक',
          'en' => '3. Open Cable Burning: Deadly Dioxin Fumes',
          _ => '3. तारों को जलाना सख्त मना व दंडनीय अपराध',
        },
        dangerBadge: switch (lang) {
          'mr' => 'कर्करोगजनक धूर • CANCER RISK',
          'en' => 'CANCER RISK (DIOXIN)',
          _ => 'कैंसरजनक धुआं • CANCER RISK',
        },
        dangerColor: const Color(0xFFDC2626),
        dos: switch (lang) {
          'mr' => [
            'इन्सुलेटेड तांब्याची वायर थेट अधिकृत रिसायकलरला विका.',
            'यांत्रिक वायर स्ट्रिपिंग मशीनचा वापर करा.',
          ],
          'en' => [
            'Sell whole insulated copper cables directly to authorized recyclers.',
            'Use mechanical cable-stripping tools instead of open flames.',
          ],
          _ => [
            'इंसुलेटेड कॉपर केबल सीधे अधिकृत रीसाइक्लर को बेचें।',
            'तार छीलने के लिए मैकेनिकल स्ट्रिपर का उपयोग करें।',
          ],
        },
        donts: switch (lang) {
          'mr' => [
            'रात्री शेतात किंवा पत्र्यावर वायर जाळू नका.',
            'या धुरातून निघणारा डायऑक्सिन विषारी वायू कर्करोग निर्माण करतो.',
          ],
          'en' => [
            'Never burn PVC cables outdoors or in metal drums.',
            'Inhaling burning PVC releases cancer-causing toxic dioxins.',
          ],
          _ => [
            'खुले में या रात में तारों को कभी न जलाएं।',
            'तारों के जलने से निकलने वाला धुआं कैंसर का कारण बनता है।',
          ],
        },
        voiceText: switch (lang) {
          'mr' => 'वायर जाळणे बेकायदेशीर आहे. यामुळे कर्करोगाचा धोका असतो. संपूर्ण केबल रिसायकलरला विका.',
          'en' => 'Open burning of cables is illegal and causes cancer. Sell whole cables directly to recyclers.',
          _ => 'तारों को आग लगाना कानूनी अपराध है। पूरी केबल अधिकृत रिसाइक्लर को सीधे बेचें।',
        },
      ),
      (
        icon: Icons.science,
        iconColor: const Color(0xFF0D9488),
        title: switch (lang) {
          'mr' => '४. ई-कचरा प्लास्टिक (BFRs युक्त)',
          'en' => '4. Electronic Plastics: Brominated Additives',
          _ => '4. ई-कचरा प्लास्टिक: जहरीले रसायन',
        },
        dangerBadge: switch (lang) {
          'mr' => 'पर्यावरणीय धोका • TOXIC PLASTIC',
          'en' => 'TOXIC ADDITIVES',
          _ => 'पर्यावरणीय खतरा • TOXIC PLASTIC',
        },
        dangerColor: const Color(0xFFD97706),
        dos: switch (lang) {
          'mr' => [
            'काळ्या व राखाडी इलेक्ट्रॉनिक बॉडी प्लास्टिकला कोरडे ठेवा.',
            'कॅटेगरीनुसार सॉर्ट करून रिसायकलरला द्या.',
          ],
          'en' => [
            'Sort black and grey electronic casings into dry segregated bins.',
            'Deliver to authorized recyclers equipped for BFR separation.',
          ],
          _ => [
            'इलेक्ट्रॉनिक प्लास्टिक बॉडी को सूखा और अलग रखें।',
            'श्रेणी के अनुसार छांटकर सीधे रीसाइक्लर को सौंपें।',
          ],
        },
        donts: switch (lang) {
          'mr' => [
            'प्लास्टिक गरम करून घरगुती वितळवू नका.',
            'पाण्यात किंवा नाल्यात कचरा टाकू नका.',
          ],
          'en' => [
            'Do not attempt to melt or heat electronic plastic scraps.',
            'Do not dump electronic casing scraps into drains or water bodies.',
          ],
          _ => [
            'प्लास्टिक को कभी भी गर्म करके पिघलाने की कोशिश न करें।',
            'पानी या नालियों में प्लास्टिक कचरा न फेंके।',
          ],
        },
        voiceText: switch (lang) {
          'mr' => 'इलेक्ट्रॉनिक प्लास्टिक कधीही आगीत वितळवू नका.',
          'en' => 'Electronic plastics contain hazardous flame retardants. Do not melt them.',
          _ => 'इलेक्ट्रॉनिक प्लास्टिक को कभी भी आग में न पिघलाएं।',
        },
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.health_and_safety_outlined, color: Color(0xFFDC2626), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        switch (lang) {
                          'mr' => 'आपले आरोग्य हीच खरी संपत्ती! ई-कचरा हाताळताना हे ४ नियम पाळा.',
                          'en' => 'Protect your health! Follow these 4 vital safety rules for scrap handling.',
                          _ => 'स्वास्थ्य ही सबसे बड़ी पूंजी है! ई-कचरा संभालते समय इन 4 नियमों का पालन करें।',
                        },
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF991B1B)),
                      ),
                    ),
                  ],
                ),
              );
            }

            final guide = guides[index - 1];

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: guide.iconColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(guide.icon, color: guide.iconColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              guide.title,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: guide.dangerColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                guide.dangerBadge,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: guide.dangerColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_outlined, color: Color(0xFF059669), size: 22),
                        tooltip: switch (lang) {
                          'mr' => 'नियम ऐका',
                          'en' => 'Listen Guide',
                          _ => 'नियम बोलकर सुनें',
                        },
                        onPressed: () => voiceService.speakSafety(guide.title, guide.voiceText, lang),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: const Color(0xFFF1F5F9)),
                  const SizedBox(height: 10),

                  // DOs
                  Text(
                    switch (lang) {
                      'mr' => '✓ काय करावे (DOs):',
                      'en' => '✓ What to Do (DOs):',
                      _ => '✓ क्या करें (DOs):',
                    },
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF059669)),
                  ),
                  const SizedBox(height: 4),
                  ...guide.dos.map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                          Expanded(
                            child: Text(
                              d,
                              style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // DONTs
                  Text(
                    switch (lang) {
                      'mr' => '✗ काय टाळावे (DONTs):',
                      'en' => '✗ What NOT to Do (DONTs):',
                      _ => '✗ क्या न करें (DONTs):',
                    },
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFFDC2626)),
                  ),
                  const SizedBox(height: 4),
                  ...guide.donts.map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                          Expanded(
                            child: Text(
                              d,
                              style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
