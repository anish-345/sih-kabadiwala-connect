import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_theme.dart';
import '../network/network_state.dart';

class NetworkStatusPill extends ConsumerWidget {
  const NetworkStatusPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netState = ref.watch(networkStateProvider);
    final notifier = ref.read(networkStateProvider.notifier);
    final isOffline = !netState.effectiveOnline;

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        onTap: () {
          notifier.toggleOfflineMode();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 2),
              content: Text(
                isOffline ? 'Online' : 'Offline mode',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: isOffline ? const Color(0xFFFFF7ED) : AppColors.bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOffline ? const Color(0xFFFDBA74) : AppColors.line,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOffline ? Icons.cloud_off_outlined : Icons.wifi,
                size: 13,
                color: isOffline ? AppColors.warn : AppColors.muted,
              ),
              const SizedBox(width: 4),
              Text(
                isOffline
                    ? 'Offline ${netState.pendingOutboxCount}'
                    : (netState.isSyncing ? 'Sync' : 'Online'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isOffline ? AppColors.warn : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        color: AppColors.ink,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
            ),
            SizedBox(width: 8),
            Text(
              'Syncing…',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF7ED),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 14, color: AppColors.warn),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline • ${netState.pendingOutboxCount} pending',
              style: const TextStyle(
                color: AppColors.warn,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => notifier.toggleOfflineMode(),
            child: const Text(
              'Go online',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
