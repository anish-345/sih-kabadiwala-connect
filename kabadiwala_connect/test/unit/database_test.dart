import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/core/storage/database.dart';
import 'package:kabadiwala_connect/core/storage/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppDatabase In-Memory SQLite Tests', () {
    late AppDatabase db;

    setUp(() async {
      db = await AppDatabase.create(inMemory: true);
    });

    tearDown(() {
      db.close();
    });

    test('insert and retrieve Material Lot', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final lot = MaterialsData(
        lotId: 'LOT-TEST-101',
        collectorId: 'COLL-001',
        category: 'PCB',
        subCategory: 'Mid Grade',
        conditionGrade: 'Grade A',
        estWeightKg: 20.0,
        estValuationInr: 3800.0,
        imageEdgeHash: 'hash123',
        createdAt: now,
      );

      db.insertMaterial(lot);

      final retrieved = db.getMaterialById('LOT-TEST-101');
      expect(retrieved, isNotNull);
      expect(retrieved?.lotId, equals('LOT-TEST-101'));
      expect(retrieved?.estWeightKg, equals(20.0));
      expect(retrieved?.estValuationInr, equals(3800.0));
    });

    test('upsert and retrieve Transaction with settlement transition', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final tx = TransactionsData(
        txId: 'TX-TEST-201',
        lotId: 'LOT-TEST-101',
        quotedValueInr: 3800.0,
        finalSettledInr: 3800.0,
        settlementMode: 'CASH',
        txLifecycleState: 'QUOTED',
        quoteTimestamp: now,
        createdAt: now,
      );

      db.upsertTransaction(tx);
      var retrieved = db.getTransactionById('TX-TEST-201');
      expect(retrieved?.txLifecycleState, equals('QUOTED'));

      // Transition to SETTLED
      final settledTx = TransactionsData(
        txId: 'TX-TEST-201',
        lotId: 'LOT-TEST-101',
        quotedValueInr: 3800.0,
        finalSettledInr: 3800.0,
        settlementMode: 'CASH',
        txLifecycleState: 'SETTLED',
        settlementTs: now + 5000,
        quoteTimestamp: now,
        createdAt: now,
      );

      db.upsertTransaction(settledTx);
      retrieved = db.getTransactionById('TX-TEST-201');
      expect(retrieved?.txLifecycleState, equals('SETTLED'));
    });

    test('outbox queuing and mark synced lifecycle', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      db.addOutbox(OutboxData(
        id: 'OUTBOX-001',
        entityType: 'TEST_TX',
        entityId: 'TX-001',
        payloadJson: '{"test":true}',
        status: 'PENDING',
        createdAt: now,
      ));

      expect(db.getPendingOutboxCount(), equals(1));
      final pending = db.getPendingOutbox();
      expect(pending.length, equals(1));
      expect(pending.first.id, equals('OUTBOX-001'));

      db.markOutboxSynced(['OUTBOX-001']);
      expect(db.getPendingOutboxCount(), equals(0));
    });
  });
}
