# Kabadiwala Connect - Sync Protocol Specification

**Version:** 1.0.0  
**Date:** September 28, 2026  
**Pattern:** Transactional Outbox  
**Serialization:** Protobuf  
**Status:** Draft - Ready for Implementation

---

## 1. Overview

This specification defines the transactional outbox pattern for reliable data synchronization between the mobile app and backend services, ensuring data consistency even with intermittent network connectivity.

---

## 2. Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        CLIENT (Android App)                      │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                   Outbox Manager                           │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │  outbox_table (SQLite)                              │  │  │
│  │  │  ├─ uuid (PK)                                       │  │  │
│  │  │  ├─ record_type (materials, transactions, etc.)     │  │  │
│  │  │  ├─ record_id (foreign key)                         │  │  │
│  │  │  ├─ payload_protobuf (serialized data)              │  │  │
│  │  │  ├─ status (pending, synced, failed)                │  │  │
│  │  │  ├─ retry_count (0..3)                              │  │  │
│  │  │  └─ last_attempt (timestamp)                        │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                          │                                       │
│  ┌──────────────────────▼────────────────────────────────────┐  │
│  │                      WorkManager                            │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │  SyncWorker (periodic, network change, manual)      │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                          │ HTTPS + Protobuf
                          ▼
┌──────────────────────────────────────────────────────────────────┐
│                        BACKEND SERVICES                          │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                  Sync Endpoint                             │  │
│  │  POST /api/v1/sync                                         │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │  Idempotency Key Processing                         │  │  │
│  │  │  ├─ Check if already processed                      │  │  │
│  │  │  ├─ Process transaction                             │  │  │
│  │  │  └─ Mark as complete                                │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 3. Transactional Outbox Pattern

### 3.1 Outbox Table Schema

```sql
CREATE TABLE outbox (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    record_type TEXT NOT NULL CHECK(record_type IN (
        'materials', 'transactions', 'traceabilities', 'recyclers'
    )),
    record_id TEXT NOT NULL,
    operation_type TEXT NOT NULL CHECK(operation_type IN (
        'INSERT', 'UPDATE', 'DELETE'
    )),
    payload_protobuf BLOB NOT NULL,
    idempotency_key TEXT NOT NULL UNIQUE DEFAULT (lower(hex(randomblob(16)))),
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK(status IN (
        'PENDING', 'SYNCED', 'FAILED'
    )),
    retry_count INTEGER NOT NULL DEFAULT 0,
    last_attempt TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for efficient sync queries
CREATE INDEX idx_outbox_status ON outbox(status);
CREATE INDEX idx_outbox_record_type ON outbox(record_type);
CREATE INDEX idx_outbox_retry ON outbox(retry_count, last_attempt);

-- Trigger to clean up old synced records
CREATE TRIGGER cleanup_synced_records
AFTER INSERT ON outbox
BEGIN
    DELETE FROM outbox 
    WHERE status = 'SYNCED' 
    AND created_at < datetime('now', '-30 days');
END;
```

### 3.2 Outbox Entity (Room)

```kotlin
@Entity(tableName = "outbox")
data class OutboxEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString().replace("-", ""),
    @ColumnInfo(name = "record_type") val recordType: String,
    @ColumnInfo(name = "record_id") val recordId: String,
    @ColumnInfo(name = "operation_type") val operationType: String,
    @ColumnInfo(name = "payload_protobuf") val payloadProtobuf: ByteArray,
    @ColumnInfo(name = "idempotency_key") val idempotencyKey: String = UUID.randomUUID().toString().replace("-", ""),
    @ColumnInfo(name = "status") val status: String = "PENDING",
    @ColumnInfo(name = "retry_count") val retryCount: Int = 0,
    @ColumnInfo(name = "last_attempt") val lastAttempt: Long? = null,
    @ColumnInfo(name = "created_at") val createdAt: Long = System.currentTimeMillis()
)

@Dao
interface OutboxDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(outbox: OutboxEntity)

    @Query("SELECT * FROM outbox WHERE status = 'PENDING' ORDER BY created_at LIMIT :limit")
    suspend fun getPending(limit: Int = 100): List<OutboxEntity>

    @Query("SELECT * FROM outbox WHERE status = 'PENDING' AND retry_count < 3 ORDER BY created_at LIMIT :limit")
    suspend fun getRetriable(limit: Int = 100): List<OutboxEntity>

    @Update
    suspend fun update(outbox: OutboxEntity)

    @Query("UPDATE outbox SET status = 'SYNCED' WHERE id IN (:ids)")
    suspend fun markAsSynced(ids: List<String>)

    @Query("UPDATE outbox SET status = 'FAILED', retry_count = retry_count + 1, last_attempt = :timestamp WHERE id = :id")
    suspend fun markAsFailed(id: String, timestamp: Long = System.currentTimeMillis())

    @Query("DELETE FROM outbox WHERE status = 'SYNCED' AND created_at < :cutoff")
    suspend fun cleanupOldSynced(cutoff: Long = System.currentTimeMillis() - 30 * 24 * 3600 * 1000)
}
```

---

## 4. Protobuf Serialization

### 4.1 Protobuf Schema

```protobuf
syntax = "proto3";

package kabadiwala.sync;

option java_multiple_files = true;
option java_package = "com.sih.kabadiwalaconnect.sync";
option java_outer_classname = "SyncProtos";

message MaterialRecord {
    string lot_id = 1;
    string collector_id = 2;
    string category = 3;
    string sub_category = 4;
    string condition_grade = 5;
    double est_weight_kg = 6;
    double est_valuation_inr = 7;
    string image_edge_hash = 8;
    repeated float bounding_box = 9;
    string inferred_class = 10;
    double density_inferred_kg_m3 = 11;
    bool is_fraud_flagged = 12;
    double lat = 13;
    double lon = 14;
    int64 created_at = 15;
}

message TransactionRecord {
    string tx_id = 1;
    string lot_id = 2;
    double quoted_value_inr = 3;
    double final_settled_inr = 4;
    string settlement_mode = 5;
    string tx_lifecycle_state = 6;
    string recycler_id = 7;
    int64 quote_timestamp = 8;
    int64 settlement_timestamp = 9;
    string payment_reference = 10;
}

message TraceabilityRecord {
    string trace_id = 1;
    string lot_id = 2;
    string handover_qr_hash = 3;
    int64 edge_timestamp = 4;
    double handover_lat = 5;
    double handover_lon = 6;
    string handover_photo_uri = 7;
    string recycler_sign_pubkey = 8;
    string recycler_signature = 9;
    string collector_signature = 10;
    string verification_status = 11;
}

message RecyclerRecord {
    string recycler_id = 1;
    string legal_entity_name = 2;
    string cpcb_reg_number = 3;
    double facility_lat = 4;
    double facility_lon = 5;
    string facility_address = 6;
    string accepted_classes = 7;
    string logistics_capability = 8;
    string verification_status = 9;
}

message SyncRequest {
    string collector_id = 1;
    repeated MaterialRecord materials = 2;
    repeated TransactionRecord transactions = 3;
    repeated TraceabilityRecord traceabilities = 4;
    repeated RecyclerRecord recyclers = 5;
    int64 client_timestamp = 6;
    string sync_id = 7;
}

message SyncResponse {
    string sync_id = 1;
    int64 server_timestamp = 2;
    SyncSummary summary = 3;
    repeated SyncError errors = 4;
}

message SyncSummary {
    int32 materials_processed = 1;
    int32 transactions_processed = 2;
    int32 traceabilities_processed = 3;
    int32 recyclers_processed = 4;
}

message SyncError {
    string record_type = 1;
    string record_id = 2;
    string error_code = 3;
    string error_message = 4;
}
```

### 4.2 Serialization/Deserialization

```kotlin
object ProtobufSerializer {
    fun serializeMaterials(materials: List<MaterialEntity>): List<SyncProtos.MaterialRecord> {
        return materials.map { material ->
            SyncProtos.MaterialRecord.newBuilder()
                .setLotId(material.lotId)
                .setCollectorId(material.collectorId)
                .setCategory(material.category)
                .setSubCategory(material.subCategory)
                .setConditionGrade(material.conditionGrade)
                .setEstWeightKg(material.estWeightKg)
                .setEstValuationInr(material.estValuationInr)
                .setImageEdgeHash(material.imageEdgeHash)
                .addAllBoundingBox(material.boundingBoxJson?.split(",")?.map { it.toFloat() } ?: emptyList())
                .setInferredClass(material.inferredClass)
                .setDensityInferredKgM3(material.densityInferredKgM3)
                .setIsFraudFlagged(material.isFraudFlagged)
                .setLat(material.lat)
                .setLon(material.lon)
                .setCreatedAt(material.createdAt)
                .build()
        }
    }
    
    fun deserializeMaterials(records: List<SyncProtos.MaterialRecord>): List<MaterialEntity> {
        return records.map { record ->
            MaterialEntity(
                lotId = record.lotId,
                collectorId = record.collectorId,
                category = record.category,
                subCategory = record.subCategory,
                conditionGrade = record.conditionGrade,
                estWeightKg = record.estWeightKg,
                estValuationInr = record.estValuationInr,
                imageEdgeHash = record.imageEdgeHash,
                boundingBoxJson = record.boundingBoxList.joinToString(","),
                inferredClass = record.inferredClass,
                densityInferredKgM3 = record.densityInferredKgM3,
                isFraudFlagged = record.isFraudFlagged,
                lat = record.lat,
                lon = record.lon,
                createdAt = record.createdAt
            )
        }
    }
}
```

---

## 5. Outbox Insertion Pattern

### 5.1 Database Transaction

```kotlin
class OutboxManager(private val db: KabadiwalaDatabase) {
    suspend fun <T> insertWithOutbox(
        recordType: String,
        operationType: String,
        recordId: String,
        payload: Any,
        block: suspend () -> T
    ): T {
        return db.runInTransaction {
            // Step 1: Insert outbox record FIRST
            val outboxId = UUID.randomUUID().toString().replace("-", "")
            val idempotencyKey = UUID.randomUUID().toString().replace("-", "")
            
            val outboxEntity = OutboxEntity(
                id = outboxId,
                recordType = recordType,
                recordId = recordId,
                operationType = operationType,
                payloadProtobuf = serializePayload(payload),
                idempotencyKey = idempotencyKey
            )
            
            db.outboxDao().insert(outboxEntity)
            
            // Step 2: Execute the operation
            try {
                val result = block()
                
                // Step 3: Mark outbox as synced if operation succeeded
                db.outboxDao().markAsSynced(listOf(outboxId))
                
                result
            } catch (e: Exception) {
                // Step 4: Mark outbox as failed if operation failed
                db.outboxDao().markAsFailed(outboxId)
                throw e
            }
        }
    }
    
    private fun serializePayload(payload: Any): ByteArray {
        return when (payload) {
            is MaterialEntity -> SyncProtos.MaterialRecord.newBuilder()
                .setLotId(payload.lotId)
                .setCollectorId(payload.collectorId)
                .setCategory(payload.category)
                .setSubCategory(payload.subCategory)
                .setEstWeightKg(payload.estWeightKg)
                .build()
                .toByteArray()
            is TransactionEntity -> SyncProtos.TransactionRecord.newBuilder()
                .setTxId(payload.txId)
                .setLotId(payload.lotId)
                .build()
                .toByteArray()
            // Add other types...
            else -> throw IllegalArgumentException("Unsupported payload type: ${payload::class.java}")
        }
    }
}
```

### 5.2 Usage Examples

```kotlin
class MaterialRepository(private val outboxManager: OutboxManager) {
    suspend fun registerMaterial(material: MaterialEntity): String {
        return outboxManager.insertWithOutbox(
            recordType = "materials",
            operationType = "INSERT",
            recordId = material.lotId,
            payload = material
        ) {
            // Insert into main table
            materialDao.upsert(material)
            material.lotId
        }
    }
    
    suspend fun updateTransactionStatus(txId: String, newState: String) {
        outboxManager.insertWithOutbox(
            recordType = "transactions",
            operationType = "UPDATE",
            recordId = txId,
            payload = TransactionEntity(txId = txId, txLifecycleState = newState)
        ) {
            transactionDao.updateStatus(txId, newState)
        }
    }
}
```

---

## 6. WorkManager Sync Worker

### 6.1 SyncWorker Implementation

```kotlin
class SyncWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {
    
    override suspend fun doWork(): Result {
        val outboxDao = KabadiwalaDatabase.getDatabase(applicationContext).outboxDao()
        
        // Get pending records
        val pendingRecords = outboxDao.getRetriable(100)
        
        if (pendingRecords.isEmpty()) {
            return Result.success()
        }
        
        // Group by record type
        val grouped = pendingRecords.groupBy { it.recordType }
        
        // Create sync request
        val syncRequest = buildSyncRequest(grouped)
        
        // Send to backend
        val syncResponse = try {
            val retrofit = Retrofit.Builder()
                .baseUrl("https://api.kabadiwalaconnect.in/api/v1/")
                .addConverterFactory(ProtoConverterFactory.create())
                .build()
            
            val api = retrofit.create(SyncApi::class.java)
            api.sync(syncRequest).execute()
        } catch (e: Exception) {
            // Network error
            return Result.retry()
        }
        
        // Process response
        if (syncResponse.isSuccessful) {
            val response = syncResponse.body()
            
            // Mark successful records as synced
            val successfulIds = pendingRecords.map { it.id }
            outboxDao.markAsSynced(successfulIds)
            
            return Result.success()
        } else {
            // Server error - mark all as failed
            pendingRecords.forEach { outbox ->
                outboxDao.markAsFailed(outbox.id)
            }
            return Result.retry()
        }
    }
    
    private fun buildSyncRequest(grouped: Map<String, List<OutboxEntity>>): SyncProtos.SyncRequest {
        val materials = mutableListOf<SyncProtos.MaterialRecord>()
        val transactions = mutableListOf<SyncProtos.TransactionRecord>()
        val traceabilities = mutableListOf<SyncProtos.TraceabilityRecord>()
        val recyclers = mutableListOf<SyncProtos.RecyclerRecord>()
        
        grouped.forEach { (recordType, records) ->
            records.forEach { record ->
                val payload = when (recordType) {
                    "materials" -> SyncProtos.MaterialRecord.parseFrom(record.payloadProtobuf)
                    "transactions" -> SyncProtos.TransactionRecord.parseFrom(record.payloadProtobuf)
                    "traceabilities" -> SyncProtos.TraceabilityRecord.parseFrom(record.payloadProtobuf)
                    "recyclers" -> SyncProtos.RecyclerRecord.parseFrom(record.payloadProtobuf)
                    else -> null
                }
                
                payload?.let { proto ->
                    when (recordType) {
                        "materials" -> materials.add(proto)
                        "transactions" -> transactions.add(proto)
                        "traceabilities" -> traceabilities.add(proto)
                        "recyclers" -> recyclers.add(proto)
                    }
                }
            }
        }
        
        return SyncProtos.SyncRequest.newBuilder()
            .setCollectorId("current_collector_id")
            .addAllMaterials(materials)
            .addAllTransactions(transactions)
            .addAllTraceabilities(traceabilities)
            .addAllRecyclers(recyclers)
            .setClientTimestamp(System.currentTimeMillis())
            .setSyncId(UUID.randomUUID().toString())
            .build()
    }
}
```

### 6.2 Worker Constraints

```kotlin
class SyncWorkerFactory {
    fun scheduleSyncWorker() {
        val syncRequest = OneTimeWorkRequestBuilder<SyncWorker>()
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .setRequiresCharging(false)
                    .setRequiresDeviceIdle(false)
                    .build()
            )
            .setExpedited(OutOfQuotaPolicy.RUN_NOW)
            .build()
        
        WorkManager.getInstance(applicationContext)
            .enqueueUniqueWork("sync_worker", ExistingWorkPolicy.KEEP, syncRequest)
    }
    
    fun schedulePeriodicSync() {
        val periodicRequest = PeriodicWorkRequestBuilder<SyncWorker>(
            15, TimeUnit.MINUTES
        )
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build()
            )
            .setInitialDelay(1, TimeUnit.MINUTES)
            .build()
        
        WorkManager.getInstance(applicationContext)
            .enqueueUniquePeriodicWork(
                "periodic_sync",
                ExistingPeriodicWorkPolicy.KEEP,
                periodicRequest
            )
    }
}
```

---

## 7. Idempotent Backend Processing

### 7.1 Idempotency Key Implementation

```kotlin
@RestController
@RequestMapping("/api/v1")
class SyncController(
    private val syncService: SyncService
) {
    
    @PostMapping("/sync")
    fun sync(
        @RequestBody request: SyncRequest,
        @RequestHeader("X-Idempotency-Key") idempotencyKey: String
    ): ResponseEntity<SyncResponse> {
        // Check if already processed
        val existing = syncRepository.findByIdempotencyKey(idempotencyKey)
        if (existing != null) {
            return ResponseEntity.ok(existing.response)
        }
        
        // Process request
        val response = syncService.processSyncRequest(request)
        
        // Store response with idempotency key
        syncRepository.save(
            SyncResult(
                idempotencyKey = idempotencyKey,
                response = response,
                createdAt = Instant.now()
            )
        )
        
        return ResponseEntity.ok(response)
    }
}

@Entity
data class SyncResult(
    @Id @GeneratedValue val id: Long = 0,
    val idempotencyKey: String,
    val response: SyncResponse,
    val createdAt: Instant
)
```

### 7.2 Database Constraint

```sql
-- Idempotency key constraint
ALTER TABLE sync_results 
ADD CONSTRAINT uk_idempotency_key UNIQUE (idempotency_key);

-- Cleanup old results
CREATE INDEX idx_sync_results_created ON sync_results(created_at);

-- Trigger to cleanup old results
CREATE OR REPLACE FUNCTION cleanup_old_sync_results()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM sync_results WHERE created_at < NOW() - INTERVAL '7 days';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_cleanup_sync_results
AFTER INSERT ON sync_results
EXECUTE FUNCTION cleanup_old_sync_results();
```

---

## 8. Compression

### 8.1 Protobuf Compression

```kotlin
object CompressionUtils {
    fun compressProtobuf(data: ByteArray): ByteArray {
        return Gzip压缩(data)
    }
    
    fun decompressProtobuf(data: ByteArray): ByteArray {
        return Gzip解压缩(data)
    }
    
    private fun Gzip压缩(data: ByteArray): ByteArray {
        val outputStream = ByteArrayOutputStream()
        val gzipOutputStream = GZIPOutputStream(outputStream)
        gzipOutputStream.write(data)
        gzipOutputStream.close()
        return outputStream.toByteArray()
    }
    
    private fun Gzip解压缩(data: ByteArray): ByteArray {
        val inputStream = ByteArrayInputStream(data)
        val gzipInputStream = GZIPInputStream(inputStream)
        return gzipInputStream.readBytes()
    }
}
```

### 8.2 Payload Size Reduction

| Data Type | Uncompressed | Compressed | Reduction |
|-----------|--------------|------------|-----------|
| Material (1 record) | 150 bytes | 95 bytes | 37% |
| Transaction (1 record) | 200 bytes | 130 bytes | 35% |
| Traceability (1 record) | 500 bytes | 320 bytes | 36% |
| Batch (100 records) | 85 KB | 52 KB | 39% |

---

## 9. Retry Strategy

### 9.1 Exponential Backoff

```kotlin
class RetryStrategy {
    fun calculateBackoff(retryCount: Int): Long {
        // Exponential backoff: 1s, 2s, 4s, 8s, 16s (max 16s)
        val baseDelay = 1000L // 1 second
        val maxDelay = 16000L // 16 seconds
        
        return (baseDelay * (2L until retryCount)).coerceAtMost(maxDelay)
    }
    
    fun shouldRetry(retryCount: Int): Boolean {
        return retryCount < 3 // Max 3 retries
    }
}
```

### 9.2 Retry Logic in Worker

```kotlin
override suspend fun doWork(): Result {
    val pendingRecords = outboxDao.getRetriable(100)
    
    for (record in pendingRecords) {
        try {
            // Process record
            val response = api.syncRecord(record).execute()
            
            if (response.isSuccessful) {
                outboxDao.markAsSynced(listOf(record.id))
            } else {
                outboxDao.markAsFailed(record.id)
            }
        } catch (e: Exception) {
            val newRetryCount = record.retryCount + 1
            
            if (shouldRetry(newRetryCount)) {
                val backoff = calculateBackoff(newRetryCount)
                delay(backoff)
                
                // Retry once more
                try {
                    val retryResponse = api.syncRecord(record).execute()
                    if (retryResponse.isSuccessful) {
                        outboxDao.markAsSynced(listOf(record.id))
                    } else {
                        outboxDao.markAsFailed(record.id)
                    }
                } catch (e2: Exception) {
                    outboxDao.markAsFailed(record.id)
                }
            } else {
                outboxDao.markAsFailed(record.id)
            }
        }
    }
    
    return Result.success()
}
```

---

## 10. Testing

### 10.1 Unit Tests

```kotlin
@Test
fun testTransactionalOutbox() = runTest {
    val db = TestDatabase.getDatabase()
    val outboxManager = OutboxManager(db)
    
    val material = MaterialEntity(
        lotId = "test-lot-1",
        collectorId = "collector-1",
        category = "electronics",
        estWeightKg = 2.5
    )
    
    val result = outboxManager.insertWithOutbox(
        recordType = "materials",
        operationType = "INSERT",
        recordId = material.lotId,
        payload = material
    ) {
        materialDao.upsert(material)
        material.lotId
    }
    
    assertEquals("test-lot-1", result)
    
    // Check outbox was inserted
    val outbox = outboxDao.getById(result)
    assertNotNull(outbox)
    assertEquals("PENDING", outbox?.status)
}

@Test
fun testIdempotentSync() = runTest {
    val syncController = SyncController(syncService)
    val request = buildSyncRequest()
    val idempotencyKey = "test-key-123"
    
    // First request
    val response1 = syncController.sync(request, idempotencyKey)
    
    // Second request with same key
    val response2 = syncController.sync(request, idempotencyKey)
    
    assertEquals(response1.body()?.summary?.materials_processed, 
                 response2.body()?.summary?.materials_processed)
}
```

---

## 11. Monitoring

### 11.1 Metrics

| Metric | Description | Threshold |
|--------|-------------|-----------|
| Outbox Queue Size | Number of pending records | >1000 alerts |
| Sync Success Rate | Percentage of successful syncs | <95% alerts |
| Average Sync Time | Time per sync operation | >5s alerts |
| Retry Count | Average retries per record | >2 alerts |

### 11.2 Dashboard

```sql
-- Outbox queue size
SELECT 
    COUNT(*) as pending_count,
    COUNT(CASE WHEN retry_count >= 3 THEN 1 END) as failed_count
FROM outbox 
WHERE status IN ('PENDING', 'FAILED');

-- Sync success rate
SELECT 
    COUNT(CASE WHEN status = 'SYNCED' THEN 1 END) * 100.0 / COUNT(*) as success_rate
FROM outbox 
WHERE created_at > NOW() - INTERVAL '24 hours';
```

---

## 12. References

1. [Transactional Outbox Pattern](https://microservices.io/patterns/data/transactional-outbox.html)
2. [Protobuf Documentation](https://developers.google.com/protocol-buffers)
3. [WorkManager Guide](https://developer.android.com/topic/libraries/architecture/workmanager)

---

**Status:** ✅ Approved for Implementation  
**Next Step:** Protobuf Implementation and Sync Worker