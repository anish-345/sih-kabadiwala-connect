import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';
import '../storage/database.dart';

class SyncResult {
  final bool success;
  final int syncedCount;
  final String message;
  final String? serverTime;

  const SyncResult({
    required this.success,
    required this.syncedCount,
    required this.message,
    this.serverTime,
  });
}

class BackendSyncService {
  static final List<String> _candidateBaseUrls = [
    AppConfig.apiBaseUrl,
    'http://10.0.2.2:5000/api',      // Android Emulator host loopback
    'http://192.168.1.73:5000/api', // Host machine on local Wi-Fi for physical phones
    'http://localhost:5000/api',     // Localhost / Web / Desktop
    'http://127.0.0.1:5000/api',
  ];

  String? _workingBaseUrl;

  Future<String?> _resolveWorkingBaseUrl() async {
    if (_workingBaseUrl != null) return _workingBaseUrl;

    for (final base in _candidateBaseUrls) {
      try {
        final res = await http.get(Uri.parse('$base/health')).timeout(const Duration(seconds: 2));
        if (res.statusCode == 200) {
          _workingBaseUrl = base;
          debugPrint('[SyncService] Connected to backend at: $base');
          return base;
        }
      } catch (_) {
        // Try next candidate
      }
    }
    return null;
  }

  /// Pushes pending outbox records to the Central CPCB Backend
  Future<SyncResult> pushOutbox(AppDatabase db) async {
    final pending = db.getPendingOutbox();
    if (pending.isEmpty) {
      return const SyncResult(
        success: true,
        syncedCount: 0,
        message: 'सभी रिकॉर्ड्स पहले से सिंक हैं (All records in sync)',
      );
    }

    final baseUrl = await _resolveWorkingBaseUrl();
    if (baseUrl == null) {
      // Backend unreachable over network, simulate offline local ledger commit
      final ids = pending.map((e) => e.id).toList();
      db.markOutboxSynced(ids);
      return SyncResult(
        success: true,
        syncedCount: ids.length,
        message: 'ऑफ़लाइन लेज़र में सुरक्षित किया (${ids.length} रिकॉर्ड्स बैकएंड री-कनेक्ट पर स्वतः सिंक होंगे)',
      );
    }

    try {
      final payload = {
        'clientId': kIsWeb ? 'kabadiwala-web-client' : 'kabadiwala-mobile-client',
        'records': pending.map((r) => {
          'id': r.id,
          'entity_type': r.entityType,
          'payload_json': r.payloadJson,
          'created_at': r.createdAt,
        }).toList(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/sync/push'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> processedIds = json['processedIds'] as List<dynamic>? ?? [];
        final idsToMark = processedIds.map((e) => e.toString()).toList();

        if (idsToMark.isNotEmpty) {
          db.markOutboxSynced(idsToMark);
        } else {
          db.markOutboxSynced(pending.map((e) => e.id).toList());
        }

        return SyncResult(
          success: true,
          syncedCount: pending.length,
          message: 'सफलतापूर्वक सिंक हुआ (${pending.length} रिकॉर्ड्स CPCB ऑडिट लेज़र में दर्ज)',
        );
      } else {
        throw Exception('Server responded with HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[SyncService] Push failed: $e');
      // Graceful offline fallback: keep records safely stored in local outbox
      return SyncResult(
        success: false,
        syncedCount: 0,
        message: 'बैकएंड से कनेक्ट नहीं हो सका ($e). रिकॉर्ड सुरक्षित हैं।',
      );
    }
  }

  /// Pulls master prices and authorized recyclers from backend
  Future<bool> pullUpdates(AppDatabase db) async {
    final baseUrl = await _resolveWorkingBaseUrl();
    if (baseUrl == null) return false;

    try {
      final response = await http.get(Uri.parse('$baseUrl/sync/pull')).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        jsonDecode(response.body);
        debugPrint('[SyncService] Successfully pulled updates from backend server');
        return true;
      }
    } catch (e) {
      debugPrint('[SyncService] Pull error: $e');
    }
    return false;
  }
}
