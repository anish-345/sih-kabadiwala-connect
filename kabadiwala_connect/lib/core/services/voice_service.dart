import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../storage/models.dart';

/// Vernacular Voice TTS service supporting Hindi, Marathi and English
class VoiceService {
  VoiceService() {
    _initTts();
  }

  FlutterTts? _tts;
  bool _isInitialized = false;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> _initTts() async {
    try {
      _tts = FlutterTts();
      await _tts?.setPitch(1.0);
      await _tts?.setSpeechRate(0.85); // Slightly slower for clear low-literacy comprehension

      _tts?.setStartHandler(() {
        _isSpeaking = true;
      });

      _tts?.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _tts?.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS Error: $msg');
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize FlutterTts: $e');
    }
  }

  Future<void> speak(String text, {String lang = 'hi'}) async {
    if (!_isInitialized) await _initTts();

    try {
      final ttsLang = switch (lang) {
        'mr' => 'mr-IN',
        'en' => 'en-IN',
        _ => 'hi-IN',
      };

      await _tts?.setLanguage(ttsLang);
      await _tts?.speak(text);
    } catch (e) {
      debugPrint('Error speaking text: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }

  /// Format and speak aloud today's market rate for a specific material
  Future<void> speakPrice(PriceFeedData price, String lang) async {
    final speechText = switch (lang) {
      'mr' => 'आज ${price.subCategory} चा भाव ${price.netOfferedPrice.toStringAsFixed(0)} रुपये प्रति किलो आहे. '
          'अधिकृत गेट भाव ${price.formalGateRate.toStringAsFixed(0)} रुपये, अधिक ईपीआर बोनस '
          '${(price.eprCreditShare + price.ncmmIncentive).toStringAsFixed(0)} रुपये.',
      'en' => 'Today\'s rate for ${price.subCategory} is ${price.netOfferedPrice.toStringAsFixed(0)} rupees per kilogram. '
          'Authorized gate price is ${price.formalGateRate.toStringAsFixed(0)} rupees plus '
          '${(price.eprCreditShare + price.ncmmIncentive).toStringAsFixed(0)} rupees EPR and strategic mineral bonus.',
      _ => 'आज ${price.subCategory} का भाव ${price.netOfferedPrice.toStringAsFixed(0)} रुपये प्रति किलो है। '
          'अधिकृत रिसाइक्लर गेट भाव ${price.formalGateRate.toStringAsFixed(0)} रुपये, और ईपीआर व खनिज बोनस '
          '${(price.eprCreditShare + price.ncmmIncentive).toStringAsFixed(0)} रुपये है।'
    };

    await speak(speechText, lang: lang);
  }

  /// Speak safety advisory for hazardous scrap handling
  Future<void> speakSafety(String title, String advice, String lang) async {
    final prefix = switch (lang) {
      'mr' => 'सावधान! सुरक्षा सूचना: ',
      'en' => 'Caution! Safety warning: ',
      _ => 'सावधान! सुरक्षा चेतावनी: ',
    };
    await speak('$prefix $title. $advice', lang: lang);
  }
}

final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService();
});
