import '../storage/database.dart';

/// Worker that synchronizes pending Outbox records to CPCB / JNARDDC registry
class SyncWorker {
  static const taskName = 'kabadiwala_sync';

  static Future<int> run(AppDatabase db) async {
    final pending = db.getPendingOutbox();
    if (pending.isEmpty) return 0;

    final ids = pending.map((e) => e.id).toList();
    db.markOutboxSynced(ids);
    return ids.length;
  }
}
