import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'db_engine.dart';
import 'db_engine_platform.dart';
import 'models.dart';

/// Real SQLite Database for Kabadiwala Connect (PS 26229)
/// Offline-first, ACID-compliant, zero code-generation fragility.
class AppDatabase {
  AppDatabase._(this._db);

  final DbEngine _db;

  // Reactive change notifiers
  final _priceChangeController = StreamController<void>.broadcast();
  final _materialChangeController = StreamController<void>.broadcast();
  final _txChangeController = StreamController<void>.broadcast();
  final _traceChangeController = StreamController<void>.broadcast();
  final _outboxChangeController = StreamController<void>.broadcast();

  static Future<AppDatabase> create({bool inMemory = false}) async {
    final db = await openPlatformDb(inMemory: inMemory);
    final appDb = AppDatabase._(db);
    appDb._initSchema();
    await appDb._seedInitialData();
    return appDb;
  }

  void _initSchema() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS price_feed (
        price_record_id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        sub_category TEXT NOT NULL,
        geo_region_code TEXT NOT NULL,
        informal_base_rate REAL NOT NULL,
        formal_gate_rate REAL NOT NULL,
        epr_credit_share REAL NOT NULL,
        ncmm_incentive REAL NOT NULL,
        net_offered_price REAL NOT NULL,
        trend TEXT NOT NULL,
        trend_delta_percent REAL DEFAULT 0.0,
        trend_history_json TEXT,
        hazard_type TEXT DEFAULT 'NONE',
        source TEXT,
        effective_from INTEGER,
        effective_to INTEGER,
        notes TEXT
      );

      CREATE TABLE IF NOT EXISTS recyclers (
        recycler_id TEXT PRIMARY KEY,
        legal_entity_name TEXT NOT NULL,
        cpcb_reg_number TEXT NOT NULL,
        facility_lat REAL NOT NULL,
        facility_lon REAL NOT NULL,
        distance_km REAL DEFAULT 5.0,
        facility_address TEXT NOT NULL,
        accepted_classes TEXT NOT NULL,
        logistics_capability TEXT NOT NULL,
        verification_status TEXT NOT NULL,
        valid_until TEXT,
        rating REAL DEFAULT 4.8,
        total_handovers INTEGER DEFAULT 0,
        price_multiplier REAL DEFAULT 1.0,
        contact_person TEXT,
        contact_phone TEXT,
        min_lot_weight_kg REAL DEFAULT 5.0,
        features_json TEXT
      );

      CREATE TABLE IF NOT EXISTS materials (
        lot_id TEXT PRIMARY KEY,
        collector_id TEXT NOT NULL,
        category TEXT NOT NULL,
        sub_category TEXT NOT NULL,
        condition_grade TEXT NOT NULL,
        est_weight_kg REAL NOT NULL,
        est_valuation_inr REAL NOT NULL,
        image_edge_hash TEXT NOT NULL,
        photo_path TEXT,
        is_fraud_flagged INTEGER DEFAULT 0,
        fraud_reason TEXT,
        lat REAL,
        lon REAL,
        created_at INTEGER NOT NULL
      );

      CREATE TABLE IF NOT EXISTS transactions (
        tx_id TEXT PRIMARY KEY,
        lot_id TEXT NOT NULL,
        quoted_value_inr REAL NOT NULL,
        final_settled_inr REAL DEFAULT 0.0,
        settlement_mode TEXT NOT NULL,
        tx_lifecycle_state TEXT NOT NULL,
        recycler_id TEXT,
        recycler_name TEXT,
        category TEXT,
        weight_kg REAL DEFAULT 0.0,
        quote_timestamp INTEGER NOT NULL,
        settlement_ts INTEGER,
        payment_reference TEXT,
        created_at INTEGER NOT NULL
      );

      CREATE TABLE IF NOT EXISTS traceability (
        trace_id TEXT PRIMARY KEY,
        lot_id TEXT NOT NULL,
        tx_id TEXT NOT NULL,
        handover_qr_hash TEXT NOT NULL,
        edge_timestamp INTEGER NOT NULL,
        handover_lat REAL NOT NULL,
        handover_lon REAL NOT NULL,
        handover_photo_uri TEXT,
        verification_status TEXT NOT NULL,
        recycler_signature TEXT,
        collector_signature TEXT,
        cpcb_batch_id TEXT,
        created_at INTEGER NOT NULL
      );

      CREATE TABLE IF NOT EXISTS outbox (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        status TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        last_attempt INTEGER
      );
    ''');
  }

  Future<void> _seedInitialData() async {
    try {
      final priceCount = _db.select('SELECT COUNT(*) as c FROM price_feed').first['c'] as int;
      if (priceCount == 0) {
        final jsonStr = await rootBundle.loadString('assets/data/prices.json');
        final List<dynamic> list = jsonDecode(jsonStr);
        for (final item in list) {
          final p = PriceFeedData.fromJson(item as Map<String, dynamic>);
          _db.execute('''
            INSERT OR REPLACE INTO price_feed (
              price_record_id, category, sub_category, geo_region_code,
              informal_base_rate, formal_gate_rate, epr_credit_share, ncmm_incentive,
              net_offered_price, trend, trend_delta_percent, trend_history_json,
              hazard_type, source, effective_from, effective_to, notes
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''', [
            p.priceRecordId,
            p.category,
            p.subCategory,
            p.geoRegionCode,
            p.informalBaseRate,
            p.formalGateRate,
            p.eprCreditShare,
            p.ncmmIncentive,
            p.netOfferedPrice,
            p.trend,
            p.trendDeltaPercent,
            jsonEncode(p.trendHistory),
            p.hazardType,
            p.source,
            p.effectiveFrom,
            p.effectiveTo,
            p.notes,
          ]);
        }
      }

      final recyclerCount = _db.select('SELECT COUNT(*) as c FROM recyclers').first['c'] as int;
      if (recyclerCount == 0) {
        final jsonStr = await rootBundle.loadString('assets/data/recyclers.json');
        final List<dynamic> list = jsonDecode(jsonStr);

        for (final item in list) {
          final r = RecyclerData.fromJson(item as Map<String, dynamic>);
          _db.execute('''
            INSERT OR REPLACE INTO recyclers (
              recycler_id, legal_entity_name, cpcb_reg_number,
              facility_lat, facility_lon, distance_km, facility_address,
              accepted_classes, logistics_capability, verification_status,
              valid_until, rating, total_handovers, price_multiplier,
              contact_person, contact_phone, min_lot_weight_kg, features_json
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''', [
            r.recyclerId,
            r.legalEntityName,
            r.cpcbRegNumber,
            r.facilityLat,
            r.facilityLon,
            r.distanceKm,
            r.facilityAddress,
            r.acceptedClasses,
            r.logisticsCapability,
            r.verificationStatus,
            r.validUntil,
            r.rating,
            r.totalHandovers,
            r.priceMultiplier,
            r.contactPerson,
            r.contactPhone,
            r.minLotWeightKg,
            jsonEncode(r.features),
          ]);
        }
      }

      // Seed 2 authentic completed field transactions if empty
      final txCount = _db.select('SELECT COUNT(*) as c FROM transactions').first['c'] as int;
      if (txCount == 0) {
        final now = DateTime.now().millisecondsSinceEpoch;
        upsertTransaction(TransactionsData(
          txId: 'TX-PUN-2026-0921',
          lotId: 'LOT-DEMO-01',
          quotedValueInr: 3800.0,
          finalSettledInr: 3800.0,
          settlementMode: 'CASH',
          txLifecycleState: 'SETTLED',
          recyclerId: 'REC-MH-PUN-001',
          recyclerName: 'E-Incarnation Recycling Pvt Ltd',
          category: 'PCB',
          weightKg: 20.0,
          quoteTimestamp: now - 86400000 * 2,
          settlementTs: now - 86400000 * 2 + 1800000,
          paymentReference: 'CASH-REC-BHO-9411',
          createdAt: now - 86400000 * 2,
        ));

        upsertTransaction(TransactionsData(
          txId: 'TX-PUN-2026-0925',
          lotId: 'LOT-DEMO-02',
          quotedValueInr: 4600.0,
          finalSettledInr: 4600.0,
          settlementMode: 'CASH',
          txLifecycleState: 'SETTLED',
          recyclerId: 'REC-MH-PUN-002',
          recyclerName: 'Eco Recycling Limited (Ecoreco Pune)',
          category: 'Cables',
          weightKg: 10.0,
          quoteTimestamp: now - 86400000,
          settlementTs: now - 86400000 + 1200000,
          paymentReference: 'CASH-REC-HAD-2041',
          createdAt: now - 86400000,
        ));
      }
    } catch (e) {
      // ignore: avoid_print
      print('Database seeding exception: $e');
    }
  }

  // ── Price Feed queries ───────────────────────────────────────────────────────
  List<PriceFeedData> getAllPrices() {
    final rows = _db.select('SELECT * FROM price_feed ORDER BY net_offered_price DESC');
    return rows.map((r) => PriceFeedData.fromRow(r)).toList();
  }

  PriceFeedData? getPriceBySubCategory(String subCategory) {
    final rows = _db.select('SELECT * FROM price_feed WHERE sub_category = ? LIMIT 1', [subCategory]);
    if (rows.isEmpty) return null;
    return PriceFeedData.fromRow(rows.first);
  }

  Stream<List<PriceFeedData>> watchPrices() async* {
    yield getAllPrices();
    await for (final _ in _priceChangeController.stream) {
      yield getAllPrices();
    }
  }

  void insertPrice(PriceFeedData p) {
    _db.execute('''
      INSERT OR REPLACE INTO price_feed (
        price_record_id, category, sub_category, geo_region_code,
        informal_base_rate, formal_gate_rate, epr_credit_share, ncmm_incentive,
        net_offered_price, trend, trend_delta_percent, trend_history_json,
        hazard_type, source, effective_from, effective_to, notes
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      p.priceRecordId,
      p.category,
      p.subCategory,
      p.geoRegionCode,
      p.informalBaseRate,
      p.formalGateRate,
      p.eprCreditShare,
      p.ncmmIncentive,
      p.netOfferedPrice,
      p.trend,
      p.trendDeltaPercent,
      jsonEncode(p.trendHistory),
      p.hazardType,
      p.source,
      p.effectiveFrom,
      p.effectiveTo,
      p.notes,
    ]);
    _priceChangeController.add(null);
  }

  // ── Recyclers queries ────────────────────────────────────────────────────────
  List<RecyclerData> getAllRecyclers() {
    final rows = _db.select('SELECT * FROM recyclers ORDER BY rating DESC, distance_km ASC');
    return rows.map((r) => RecyclerData.fromRow(r)).toList();
  }

  RecyclerData? getRecyclerById(String id) {
    final rows = _db.select('SELECT * FROM recyclers WHERE recycler_id = ? LIMIT 1', [id]);
    if (rows.isEmpty) return null;
    return RecyclerData.fromRow(rows.first);
  }

  void insertRecycler(RecyclerData r) {
    _db.execute('''
      INSERT OR REPLACE INTO recyclers (
        recycler_id, legal_entity_name, cpcb_reg_number,
        facility_lat, facility_lon, distance_km, facility_address,
        accepted_classes, logistics_capability, verification_status,
        valid_until, rating, total_handovers, price_multiplier,
        contact_person, contact_phone, min_lot_weight_kg, features_json
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      r.recyclerId,
      r.legalEntityName,
      r.cpcbRegNumber,
      r.facilityLat,
      r.facilityLon,
      r.distanceKm,
      r.facilityAddress,
      r.acceptedClasses,
      r.logisticsCapability,
      r.verificationStatus,
      r.validUntil,
      r.rating,
      r.totalHandovers,
      r.priceMultiplier,
      r.contactPerson,
      r.contactPhone,
      r.minLotWeightKg,
      jsonEncode(r.features),
    ]);
  }

  // ── Materials / Lots queries ─────────────────────────────────────────────────
  void insertMaterial(MaterialsData lot) {
    _db.execute('''
      INSERT OR REPLACE INTO materials (
        lot_id, collector_id, category, sub_category, condition_grade,
        est_weight_kg, est_valuation_inr, image_edge_hash, photo_path,
        is_fraud_flagged, fraud_reason, lat, lon, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      lot.lotId,
      lot.collectorId,
      lot.category,
      lot.subCategory,
      lot.conditionGrade,
      lot.estWeightKg,
      lot.estValuationInr,
      lot.imageEdgeHash,
      lot.photoPath,
      lot.isFraudFlagged ? 1 : 0,
      lot.fraudReason,
      lot.lat,
      lot.lon,
      lot.createdAt,
    ]);
    _materialChangeController.add(null);
  }

  List<MaterialsData> getAllMaterials() {
    final rows = _db.select('SELECT * FROM materials ORDER BY created_at DESC');
    return rows.map((r) => MaterialsData.fromRow(r)).toList();
  }

  MaterialsData? getMaterialById(String id) {
    final rows = _db.select('SELECT * FROM materials WHERE lot_id = ? LIMIT 1', [id]);
    if (rows.isEmpty) return null;
    return MaterialsData.fromRow(rows.first);
  }

  Stream<List<MaterialsData>> watchMaterials() async* {
    yield getAllMaterials();
    await for (final _ in _materialChangeController.stream) {
      yield getAllMaterials();
    }
  }

  // ── Transactions queries ─────────────────────────────────────────────────────
  void upsertTransaction(TransactionsData tx) {
    _db.execute('''
      INSERT OR REPLACE INTO transactions (
        tx_id, lot_id, quoted_value_inr, final_settled_inr,
        settlement_mode, tx_lifecycle_state, recycler_id, recycler_name,
        category, weight_kg, quote_timestamp, settlement_ts,
        payment_reference, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      tx.txId,
      tx.lotId,
      tx.quotedValueInr,
      tx.finalSettledInr,
      tx.settlementMode,
      tx.txLifecycleState,
      tx.recyclerId,
      tx.recyclerName,
      tx.category,
      tx.weightKg,
      tx.quoteTimestamp,
      tx.settlementTs,
      tx.paymentReference,
      tx.createdAt,
    ]);
    _txChangeController.add(null);
  }

  List<TransactionsData> getAllTransactions() {
    final rows = _db.select('SELECT * FROM transactions ORDER BY created_at DESC');
    return rows.map((r) => TransactionsData.fromRow(r)).toList();
  }

  TransactionsData? getTransactionById(String id) {
    final rows = _db.select('SELECT * FROM transactions WHERE tx_id = ? LIMIT 1', [id]);
    if (rows.isEmpty) return null;
    return TransactionsData.fromRow(rows.first);
  }

  TransactionsData? getTransactionByLotId(String lotId) {
    final rows = _db.select('SELECT * FROM transactions WHERE lot_id = ? LIMIT 1', [lotId]);
    if (rows.isEmpty) return null;
    return TransactionsData.fromRow(rows.first);
  }

  Stream<List<TransactionsData>> watchTransactions() async* {
    yield getAllTransactions();
    await for (final _ in _txChangeController.stream) {
      yield getAllTransactions();
    }
  }

  // ── Traceability queries ─────────────────────────────────────────────────────
  void insertTraceability(TraceabilityData trace) {
    _db.execute('''
      INSERT OR REPLACE INTO traceability (
        trace_id, lot_id, tx_id, handover_qr_hash, edge_timestamp,
        handover_lat, handover_lon, handover_photo_uri, verification_status,
        recycler_signature, collector_signature, cpcb_batch_id, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      trace.traceId,
      trace.lotId,
      trace.txId,
      trace.handoverQrHash,
      trace.edgeTimestamp,
      trace.handoverLat,
      trace.handoverLon,
      trace.handoverPhotoUri,
      trace.verificationStatus,
      trace.recyclerSignature,
      trace.collectorSignature,
      trace.cpcbBatchId,
      trace.createdAt,
    ]);
    _traceChangeController.add(null);
  }

  TraceabilityData? getTraceabilityById(String id) {
    final rows = _db.select('SELECT * FROM traceability WHERE trace_id = ? LIMIT 1', [id]);
    if (rows.isEmpty) return null;
    return TraceabilityData.fromRow(rows.first);
  }

  TraceabilityData? getTraceabilityByLotId(String lotId) {
    final rows = _db.select('SELECT * FROM traceability WHERE lot_id = ? LIMIT 1', [lotId]);
    if (rows.isEmpty) return null;
    return TraceabilityData.fromRow(rows.first);
  }

  // ── Outbox queries (Offline-First Sync) ──────────────────────────────────────
  void addOutbox(OutboxData outbox) {
    _db.execute('''
      INSERT OR REPLACE INTO outbox (
        id, entity_type, entity_id, payload_json, status, retry_count, created_at, last_attempt
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      outbox.id,
      outbox.entityType,
      outbox.entityId,
      outbox.payloadJson,
      outbox.status,
      outbox.retryCount,
      outbox.createdAt,
      outbox.lastAttempt,
    ]);
    _outboxChangeController.add(null);
  }

  List<OutboxData> getPendingOutbox() {
    final rows = _db.select("SELECT * FROM outbox WHERE status = 'PENDING' ORDER BY created_at ASC");
    return rows.map((r) => OutboxData.fromRow(r)).toList();
  }

  int getPendingOutboxCount() {
    final rows = _db.select("SELECT COUNT(*) as c FROM outbox WHERE status = 'PENDING'");
    return rows.first['c'] as int;
  }

  void markOutboxSynced(List<String> ids) {
    for (final id in ids) {
      _db.execute("UPDATE outbox SET status = 'SYNCED', last_attempt = ? WHERE id = ?", [
        DateTime.now().millisecondsSinceEpoch,
        id,
      ]);
    }
    _outboxChangeController.add(null);
  }

  Stream<int> watchPendingOutboxCount() async* {
    yield getPendingOutboxCount();
    await for (final _ in _outboxChangeController.stream) {
      yield getPendingOutboxCount();
    }
  }

  void close() {
    _priceChangeController.close();
    _materialChangeController.close();
    _txChangeController.close();
    _traceChangeController.close();
    _outboxChangeController.close();
    _db.close();
  }
}

// Global Provider overridden in main.dart
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden in ProviderScope');
});
