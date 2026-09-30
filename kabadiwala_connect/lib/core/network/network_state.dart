import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/database.dart';
import 'backend_sync_service.dart';

class NetworkState {
  final bool isConnected;
  final bool isSimulatedOffline;
  final bool isSyncing;
  final int pendingOutboxCount;
  final String? lastSyncMessage;

  const NetworkState({
    required this.isConnected,
    this.isSimulatedOffline = false,
    this.isSyncing = false,
    this.pendingOutboxCount = 0,
    this.lastSyncMessage,
  });

  bool get effectiveOnline => isConnected && !isSimulatedOffline;

  NetworkState copyWith({
    bool? isConnected,
    bool? isSimulatedOffline,
    bool? isSyncing,
    int? pendingOutboxCount,
    String? lastSyncMessage,
  }) {
    return NetworkState(
      isConnected: isConnected ?? this.isConnected,
      isSimulatedOffline: isSimulatedOffline ?? this.isSimulatedOffline,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingOutboxCount: pendingOutboxCount ?? this.pendingOutboxCount,
      lastSyncMessage: lastSyncMessage ?? this.lastSyncMessage,
    );
  }
}

class NetworkStateNotifier extends StateNotifier<NetworkState> {
  NetworkStateNotifier(this._db)
      : super(const NetworkState(isConnected: true, isSimulatedOffline: false)) {
    _init();
  }

  final AppDatabase _db;
  StreamSubscription? _connectivitySub;
  StreamSubscription? _outboxSub;

  void _init() {
    // Watch pending outbox
    _outboxSub = _db.watchPendingOutboxCount().listen((count) {
      state = state.copyWith(pendingOutboxCount: count);
    });

    // Watch system network connectivity
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      state = state.copyWith(isConnected: isOnline);
      if (state.effectiveOnline && state.pendingOutboxCount > 0) {
        triggerSync();
      }
    });
  }

  /// Toggle Airplane Mode simulation for demoing offline capabilities
  void toggleOfflineMode() {
    final nextSim = !state.isSimulatedOffline;
    state = state.copyWith(isSimulatedOffline: nextSim);

    if (!nextSim && state.isConnected) {
      // Reconnected! Trigger sync
      triggerSync();
    }
  }

  final _syncService = BackendSyncService();

  /// Synchronize outbox queue to Central CPCB Backend registry
  Future<void> triggerSync() async {
    if (state.isSyncing) return;
    state = state.copyWith(isSyncing: true);

    try {
      final result = await _syncService.pushOutbox(_db);
      await _syncService.pullUpdates(_db);

      state = state.copyWith(
        isSyncing: false,
        pendingOutboxCount: _db.getPendingOutbox().length,
        lastSyncMessage: result.message,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        lastSyncMessage: 'सिंक विफल: $e',
      );
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _outboxSub?.cancel();
    super.dispose();
  }
}

final networkStateProvider =
    StateNotifierProvider<NetworkStateNotifier, NetworkState>((ref) {
  final db = ref.watch(databaseProvider);
  return NetworkStateNotifier(db);
});
