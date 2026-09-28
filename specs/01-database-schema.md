# Kabadiwala Connect - Database Schema Specification
### SIH 2026 Problem Statement 26229 (Ministry of Mines / JNARDDC)

**Version:** 2.0.0 (Production Flutter / SQLite Engine)  
**Engine:** SQLite3 with `sqlite3_flutter_libs` & Reactive Streams  
**Status:** Implemented & Verified with Automated Test Suite  

---

## 1. Architecture Overview

The database is built for **100% offline-first reliability** using an embedded, zero-dependency SQLite engine. All queries, transactions, and index lookups operate directly against local disk storage (`kabadiwala_connect.db` in app documents directory).

The schema comprises 6 core tables:
1. `price_feed` - Offline cached price discovery feed with informal base, formal gate, EPR credit, and NCMM mineral incentive rates.
2. `recyclers` - CPCB-authorized dismantler and recycler registry with geo-coordinates, logistics capability, and ratings.
3. `materials` - Physical lot registry recording category, sub-category, scale weights, and density fraud flags.
4. `transactions` - Financial handover ledger recording quoted values, settlement timestamps, spot cash payments, and payment references.
5. `traceability` - Cryptographic dual-custody verification chain holding HMAC-SHA256 hashes, timestamps, and GPS coordinates.
6. `outbox` - Queued operations for asynchronous synchronization to the CPCB national EPR portal upon reconnection.

---

## 2. Table Schemas (DDL)

```sql
CREATE TABLE price_feed (
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

CREATE TABLE recyclers (
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

CREATE TABLE materials (
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

CREATE TABLE transactions (
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

CREATE TABLE traceability (
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

CREATE TABLE outbox (
  id TEXT PRIMARY KEY,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  payload_json TEXT NOT NULL,
  status TEXT NOT NULL,
  retry_count INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  last_attempt INTEGER
);
```

---

## 3. Implementation Mapping

The schema is implemented in `lib/core/storage/database.dart` via `AppDatabase`, with typed data classes in `lib/core/storage/models.dart`.
- In-memory execution: `AppDatabase.create(inMemory: true)` used for automated test suites.
- Persistent execution: `AppDatabase.create()` used in production APK, storing data in SQLite database file.
- Reactive streams: `watchPrices()`, `watchMaterials()`, `watchTransactions()`, and `watchPendingOutboxCount()` notify UI subscribers instantly upon SQLite write operations.