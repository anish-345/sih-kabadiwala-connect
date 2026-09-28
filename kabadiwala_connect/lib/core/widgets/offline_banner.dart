import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/network_state.dart';

/// App Bar action pill allowing instant Airplane / Offline Mode simulation
class NetworkStatusPill extends ConsumerWidget {
  const NetworkStatusPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netState = ref.watch(networkStateProvider);
    final notifier = ref.read(networkStateProvider.notifier);

    final isOffline = !netState.effectiveOnline;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          notifier.toggleOfflineMode();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 2),
              content: Text(
                isOffline
                    ? 'ऑनलाइन मोड सक्षम: नेटवर्क कनेक्शन सक्रिय'
                    : 'हवाई जहाज़ / ऑफ़लाइन मोड सक्रिय: सभी कार्य बिना इंटरनेट के चलेंगे',
              ),
              backgroundColor: isOffline ? Colors.green.shade800 : Colors.amber.shade900,
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isOffline ? Colors.amber.shade900.withOpacity(0.9) : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOffline ? Colors.amber.shade300 : Colors.white70,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOffline ? Icons.airplanemode_active : Icons.wifi,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                isOffline
                    ? 'ऑफ़लाइन (${netState.pendingOutboxCount})'
                    : (netState.isSyncing ? 'सिंक हो रहा है…' : 'ऑनलाइन'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating Banner shown across screens when in offline mode or during sync
class OfflineSyncBanner extends ConsumerWidget {
  const OfflineSyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netState = ref.watch(networkStateProvider);
    final notifier = ref.read(networkStateProvider.notifier);

    if (netState.effectiveOnline && !netState.isSyncing) {
      return const SizedBox.shrink();
    }

    if (netState.isSyncing) {
      return Container(
        width: double.infinity,
        color: Colors.blue.shade800,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 8),
            Text(
              'CPCB पोर्टल व राष्ट्रीय खनिज मिशन लेज़र से सिंक हो रहा है…',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      color: Colors.orange.shade900,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'ऑफ़लाइन मोड (स्थानीय SQLite सक्रिय) • लंबित सिंक: ${netState.pendingOutboxCount}',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => notifier.toggleOfflineMode(),
            child: const Text(
              'ऑनलाइन करें',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
