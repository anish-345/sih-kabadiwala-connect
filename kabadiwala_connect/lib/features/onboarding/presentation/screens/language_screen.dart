import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/app_state.dart';
import '../../../../core/services/voice_service.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  String _selectedLang = 'hi';

  @override
  void initState() {
    super.initState();
    _selectedLang = ref.read(appStateProvider).language;
  }

  final List<({String code, String nativeName, String englishName, String greeting})> _languages = [
    (
      code: 'hi',
      nativeName: 'हिन्दी',
      englishName: 'Hindi',
      greeting: 'नमस्ते! कबाड़ीवाला कनेक्ट में आपका स्वागत है। अपनी भाषा चुनें।',
    ),
    (
      code: 'mr',
      nativeName: 'मराठी',
      englishName: 'Marathi',
      greeting: 'नमस्कार! कबाडीवाला कनेक्ट मध्ये आपले स्वागत आहे. आपली भाषा निवडा.',
    ),
    (
      code: 'en',
      nativeName: 'English',
      englishName: 'English',
      greeting: 'Welcome to Kabadiwala Connect. Select your language to proceed.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final voiceService = ref.watch(voiceServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // App Logo & Header
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.recycling,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'कबाड़ीवाला कनेक्ट',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Kabadiwala Connect • PS 26229',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: const Text(
                  'खान मंत्रालय / JNARDDC समर्थित',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'भाषा चुनें / Select Language',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: Color(0xFF2E7D32), size: 28),
                    tooltip: 'बोलकर सुनें (Listen)',
                    onPressed: () {
                      final selected = _languages.firstWhere((l) => l.code == _selectedLang);
                      voiceService.speak(selected.greeting, lang: _selectedLang);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Language Cards
              Expanded(
                child: ListView.separated(
                  itemCount: _languages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final lang = _languages[index];
                    final isSelected = _selectedLang == lang.code;

                    return InkWell(
                      onTap: () {
                        setState(() => _selectedLang = lang.code);
                        ref.read(appStateProvider.notifier).setLanguage(lang.code);
                        voiceService.speak(lang.greeting, lang: lang.code);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                            width: isSelected ? 2.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  lang.nativeName.substring(0, 1),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.nativeName,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? const Color(0xFF1B5E20) : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    lang.englishName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF2E7D32),
                                size: 28,
                              )
                            else
                              Icon(
                                Icons.circle_outlined,
                                color: Colors.grey.shade400,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Continue Button
              FilledButton(
                onPressed: () {
                  ref.read(appStateProvider.notifier).setLanguage(_selectedLang);
                  context.push(AppRoutes.role);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  switch (_selectedLang) {
                    'mr' => 'पुढे जा (Continue) →',
                    'en' => 'Continue →',
                    _ => 'आगे बढ़ें (Continue) →',
                  },
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
