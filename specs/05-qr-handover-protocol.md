# Kabadiwala Connect - QR Handover Protocol Specification

**Version:** 1.0.0  
**Date:** September 28, 2026  
**Security:** ECDSA secp256r1 Digital Signatures  
**Verification:** Dual-Custody Photo Authentication  
**Status:** Draft - Ready for Implementation

---

## 1. Overview

This specification defines the verifiable digital handover protocol using ECDSA-signed QR codes with dual-custody photo verification for secure e-waste scrap transactions between collectors and recyclers.

---

## 2. Protocol Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                      COLLECTOR DEVICE                            │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                  Scanner Activity                          │  │
│  │  1. Material scanned with CV model                        │  │
│  │  2. Material registered in local DB                       │  │
│  │  3. Transaction created with provisional status           │  │
│  │  4. ECDSA key pair generated for this transaction         │  │
│  │  5. QR code generated with signed transaction data        │  │
│  └───────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                          │
                          │ QR Code Scanned
                          ▼
┌──────────────────────────────────────────────────────────────────┐
│                      RECycler DEVICE                             │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                  Handover Activity                         │  │
│  │  1. QR code scanned from collector's device               │  │
│  │  2. ECDSA signature verified with collector's public key  │  │
│  │  3. Dual-custody photo verification                       │  │
│  │  4. Transaction confirmed and payment initiated           │  │
│  └───────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────────────┐
│                      BACKEND VERIFICATION                        │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                  Sync Service                              │  │
│  │  1. Recipient's public key from recycler registry         │  │
│  │  2. Signature verification                                │  │
│  │  3. Transaction finalized in distributed ledger           │  │
│  └───────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 3. QR Code Structure

### 3.1 QR Code Format

```
┌─────────────────────────────────────────────────────────────────────┐
│                              QR CODE                                │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  {                                                    }       │  │
│  │  {  "tx_id": "uuid-uuid-uuid",                       }       │  │
│  │  {  "lot_id": "uuid-uuid-uuid",                      }       │  │
│  │  {  "collector_id": "sha256_hash_of_phone",          }       │  │
│  │  {  "timestamp": 1695897600000,                      }       │  │
│  │  {  "lat": 28.7041,                                  }       │  │
│  │  {  "lon": 77.1025,                                  }       │  │
│  │  {  "material": {                                    }       │  │
│  │  {    "category": "electronics",                     }       │  │
│  │  {    "sub_category": "pcb",                         }       │  │
│  │  {    "est_weight_kg": 2.5                           }       │  │
│  │  {  },                                               }       │  │
│  │  {  "price": {                                       }       │  │
│  │  {    "quoted_value_inr": 250.0,                     }       │  │
│  │  {    "net_offered_price_inr": 396.50                }       │  │
│  │  {  },                                               }       │  │
│  │  {  "public_key": "base64_encoded_ecdsa_public_key", }       │  │
│  │  {  "signature": "base64_encoded_ecdsa_signature",   }       │  │
│  │  {  "expires_at": 1695984000000                      }       │  │
│  │  {                                                    }       │  │
│  │  └───────────────────────────────────────────────────┘       │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

### 3.2 JSON Payload Structure

```json
{
  "tx_id": "550e8400-e29b-41d4-a716-446655440000",
  "lot_id": "550e8400-e29b-41d4-a716-446655440001",
  "collector_id": "a1b2c3d4e5f6...",
  "timestamp": 1695897600000,
  "lat": 28.7041,
  "lon": 77.1025,
  "material": {
    "category": "electronics",
    "sub_category": "pcb",
    "est_weight_kg": 2.5
  },
  "price": {
    "quoted_value_inr": 250.0,
    "net_offered_price_inr": 396.50
  },
  "public_key": "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...",
  "signature": "MEUCIQDJx5b7Jf1VzKpLqRmN...",
  "expires_at": 1695984000000
}
```

---

## 4. ECDSA Signature Protocol

### 4.1 Key Generation

```kotlin
fun generateECDSAKeyPair(): ECKeyPair {
    // Use secp256r1 curve (NIST P-256)
    val keyPairGenerator = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC)
    val keyGenParameterSpec = KeyGenParameterSpec.Builder(
        "kabadiwala_tx_${UUID.randomUUID()}",
        KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
    )
    .setKeySize(256)
    .setSignaturePaddings(KeyProperties.SIGNATURE_PADDING_RSA_PKCS1)
    .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
    .setUserAuthenticationRequired(false)
    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_RSA_OAEP)
    .build()
    
    keyPairGenerator.initialize(keyGenParameterSpec)
    val keyPair = keyPairGenerator.generateKeyPair()
    
    val privateKey = keyPair.private
    val publicKey = keyPair.public
    
    return ECKeyPair(
        privateKey = privateKey.encoded,
        publicKey = publicKey.encoded,
        keyId = keyGenParameterSpec.keyAlias
    )
}

data class ECKeyPair(
    val privateKey: ByteArray,
    val publicKey: ByteArray,
    val keyId: String
)
```

### 4.2 Signing Process

```kotlin
fun signQRData(
    collectorId: String,
    txId: String,
    lotId: String,
    timestamp: Long,
    lat: Double,
    lon: Double,
    material: MaterialData,
    price: PriceData,
    privateKey: PrivateKey
): String {
    // Create payload JSON
    val payload = JsonObject().apply {
        addProperty("collector_id", collectorId)
        addProperty("tx_id", txId)
        addProperty("lot_id", lotId)
        addProperty("timestamp", timestamp)
        addProperty("lat", lat)
        addProperty("lon", lon)
        add("material", JsonObject().apply {
            addProperty("category", material.category)
            addProperty("sub_category", material.subCategory)
            addProperty("est_weight_kg", material.estWeightKg)
        })
        add("price", JsonObject().apply {
            addProperty("quoted_value_inr", price.quotedValueInr)
            addProperty("net_offered_price_inr", price.netOfferedPriceInr)
        })
        addProperty("expires_at", timestamp + 86400000)  // 24 hours
    }.toString()
    
    // Sign the payload
    val signature = signData(payload, privateKey)
    
    // Add public key to payload
    val signedPayload = JsonObject().apply {
        addProperty("payload", Base64.encodeToString(payload.toByteArray(), Base64.NO_WRAP))
        addProperty("signature", signature)
    }.toString()
    
    return signedPayload
}

fun signData(data: String, privateKey: PrivateKey): String {
    val signature = Signature.getInstance("SHA256withECDSA")
    signature.initSign(privateKey)
    signature.update(data.toByteArray())
    val signed = signature.sign()
    return Base64.encodeToString(signed, Base64.NO_WRAP)
}
```

### 4.3 Verification Process

```kotlin
fun verifyQRSignature(
    signedPayload: String,
    publicKey: PublicKey
): VerificationResult {
    return try {
        val payloadObj = JsonParser.parseString(signedPayload).asJsonObject
        val payload = String(Base64.decode(payloadObj.get("payload").asString, Base64.NO_WRAP))
        val signature = Base64.decode(payloadObj.get("signature").asString, Base64.NO_WRAP)
        
        // Verify signature
        val sig = Signature.getInstance("SHA256withECDSA")
        sig.initVerify(publicKey)
        sig.update(payload.toByteArray())
        val isValid = sig.verify(signature)
        
        if (isValid) {
            // Parse and validate payload
            val payloadJson = JsonParser.parseString(payload).asJsonObject
            val expiresAt = payloadJson.get("expires_at").asLong
            val currentTimestamp = System.currentTimeMillis()
            
            if (currentTimestamp > expiresAt) {
                VerificationResult.Expired
            } else {
                VerificationResult.Valid(payloadJson)
            }
        } else {
            VerificationResult.InvalidSignature
        }
    } catch (e: Exception) {
        VerificationResult.Error(e.message ?: "Verification failed")
    }
}

sealed class VerificationResult {
    data class Valid(val payload: JsonObject) : VerificationResult()
    object Expired : VerificationResult()
    object InvalidSignature : VerificationResult()
    data class Error(val message: String) : VerificationResult()
}
```

---

## 5. Dual-Custody Photo Verification

### 5.1 Photo Requirements

| Requirement | Specification | Purpose |
|-------------|---------------|---------|
| **Format** | JPEG/PNG | Standard image format |
| **Resolution** | Minimum 1920x1080 | Clear photo quality |
| **Size** | <5 MB | Manageable file size |
| **Timestamp** | Embedded EXIF | Proof of capture time |
| **Location** | GPS EXIF tags | Proof of capture location |

### 5.2 Photo Capture Flow

```kotlin
class DualCustodyPhotoManager {
    suspend fun captureCollectorPhoto(): PhotoData {
        // Open camera
        val imageCapture = ImageCapture.Builder().build()
        
        // Capture photo with GPS metadata
        val exif = ExifInterface.createFromString(
            ExifInterface().apply {
                setAttribute(ExifInterface.TAG_GPS_LATITUDE, collectorLat.toString())
                setAttribute(ExifInterface.TAG_GPS_LONGITUDE, collectorLon.toString())
                setAttribute(ExifInterface.TAG_TIMESTAMP, System.currentTimeMillis().toString())
            }.toString()
        )
        
        val photoFile = File.createTempFile("collector_photo_", ".jpg", context.cacheDir)
        val outputOptions = ImageCapture.OutputFileOptions.Builder(photoFile).build()
        
        imageCapture.takePicture(outputOptions, ContextCompat.getMainExecutor(context), object : ImageCapture.OnImageCapturedCallback() {
            override fun onCaptureSuccess(imageInfo: ImageCapture.ImageInfo) {
                // Success
            }
            override fun onError(error: ImageCaptureException) {
                // Error handling
            }
        })
        
        return PhotoData(
            uri = photoFile.toUri(),
            timestamp = System.currentTimeMillis(),
            lat = collectorLat,
            lon = collectorLon
        )
    }
    
    suspend fun captureRecyclerPhoto(): PhotoData {
        // Similar to collector photo, but at recycler facility
        // Include recycler QR code in frame
        return PhotoData(...)
    }
    
    fun verifyPhotosIntegrity(collectorPhoto: PhotoData, recyclerPhoto: PhotoData): Boolean {
        // Check timestamps are within 5 minutes of each other
        val timeDiff = kotlin.math.abs(collectorPhoto.timestamp - recyclerPhoto.timestamp)
        if (timeDiff > 300000) return false  // 5 minutes
        
        // Check locations are close (within 100m)
        val distance = calculateDistance(
            collectorPhoto.lat, collectorPhoto.lon,
            recyclerPhoto.lat, recyclerPhoto.lon
        )
        if (distance > 100) return false  // 100 meters
        
        // Check EXIF metadata authenticity
        return checkPhotoMetadata(collectorPhoto.uri) && checkPhotoMetadata(recyclerPhoto.uri)
    }
}
```

### 5.3 Photo Storage

```kotlin
data class HandoverPhoto(
    val photoId: String = UUID.randomUUID().toString(),
    val lotId: String,
    val photoType: PhotoType,
    val collectorPhotoUri: String,
    val recyclerPhotoUri: String,
    val verificationStatus: VerificationStatus
)

enum class PhotoType {
    COLLECTOR_HANDOVER,
    RECycler_ACCEPTANCE,
    BOTH_PHOTOS
}

enum class VerificationStatus {
    PENDING,
    VERIFIED,
    REJECTED
}
```

---

## 6. QR Code Generation & Scanning

### 6.1 QR Code Generation

```kotlin
class QRCodeGenerator {
    fun generateQRCode(
        collectorId: String,
        txId: String,
        lotId: String,
        timestamp: Long,
        lat: Double,
        lon: Double,
        material: MaterialData,
        price: PriceData,
        privateKey: PrivateKey
    ): Bitmap {
        val signedPayload = signQRData(
            collectorId, txId, lotId, timestamp, lat, lon, material, price, privateKey
        )
        
        val matrix = MultiFormatWriter().encode(
            signedPayload,
            BarcodeFormat.QR_CODE,
            512,
            512
        )
        
        val bitmap = Bitmap.createBitmap(512, 512, Bitmap.Config.ARGB_8888)
        for (x in 0 until 512) {
            for (y in 0 until 512) {
                bitmap.setPixel(x, y, if (matrix.get(x, y)) Color.BLACK else Color.WHITE)
            }
        }
        
        return bitmap
    }
}
```

### 6.2 QR Code Scanning

```kotlin
class QRCodeScanner {
    private val barcodeScanner = BarcodeScanning.getClient(
        BarcodeScannerOptions.Builder()
            .setBarcodeFormats(Barcode.FORMAT_QR_CODE)
            .build()
    )
    
    suspend fun scanQRCode(image: InputImage): QRScanResult {
        return try {
            val barcodes = barcodeScanner.process(image)
            
            if (barcodes.isEmpty()) {
                QRScanResult.NoBarcode
            } else {
                val qrCode = barcodes[0]
                val rawValue = qrCode.rawValue
                
                QRScanResult.Success(rawValue)
            }
        } catch (e: Exception) {
            QRScanResult.Error(e.message ?: "Scan failed")
        }
    }
    
    sealed class QRScanResult {
        data class Success(val rawValue: String) : QRScanResult()
        object NoBarcode : QRScanResult()
        data class Error(val message: String) : QRScanResult()
    }
}
```

---

## 7. Transaction Flow

### 7.1 Handover Initiation (Collector)

```kotlin
class HandoverInitiator {
    suspend fun initiateHandover(lotId: String, price: PriceData): QRHandoverResult {
        // 1. Get material data
        val material = materialDao.getById(lotId) ?: return QRHandoverResult.Error("Material not found")
        
        // 2. Generate ECDSA key pair
        val keyPair = generateECDSAKeyPair()
        
        // 3. Create transaction
        val txId = UUID.randomUUID().toString()
        val transaction = TransactionEntity(
            txId = txId,
            lotId = lotId,
            quotedValueInr = price.quotedValueInr,
            finalSettledInr = 0.0,
            settlementMode = "pending",
            txLifecycleState = "pending",
            createdAt = System.currentTimeMillis()
        )
        transactionDao.upsert(transaction)
        
        // 4. Generate QR code
        val qrBitmap = qrCodeGenerator.generateQRCode(
            collectorId = "current_collector_id",
            txId = txId,
            lotId = lotId,
            timestamp = System.currentTimeMillis(),
            lat = currentLat,
            lon = currentLon,
            material = material,
            price = price,
            privateKey = keyPair.privateKey
        )
        
        // 5. Save public key to local storage
        publicKeyStorage.saveKeyPair(keyPair, txId)
        
        // 6. Return QR code for display
        return QRHandoverResult.Success(qrBitmap, txId)
    }
}
```

### 7.2 Handover Verification (Recycler)

```kotlin
class HandoverVerifier {
    suspend fun verifyHandover(qrData: String, collectorLocation: LocationData): HandoverVerificationResult {
        // 1. Parse and verify QR signature
        val verificationResult = verifyQRSignature(qrData)
        
        when (verificationResult) {
            is VerificationResult.Valid -> {
                val payload = verificationResult.payload
                
                // 2. Verify collector's public key from registry
                val collectorPublicKey = recyclerDao.getPublicKey(payload.collector_id)
                    ?: return HandoverVerificationResult.Error("Collector public key not found")
                
                // 3. Re-verify signature with registry key
                val isValid = verifySignature(qrData, collectorPublicKey)
                if (!isValid) return HandoverVerificationResult.InvalidSignature
                
                // 4. Check QR expiration
                if (System.currentTimeMillis() > payload.expires_at) {
                    return HandoverVerificationResult.Expired
                }
                
                // 5. Capture dual-custody photos
                val collectorPhoto = photoManager.captureCollectorPhoto()
                val recyclerPhoto = photoManager.captureRecyclerPhoto()
                
                // 6. Verify photo integrity
                val photosValid = photoManager.verifyPhotosIntegrity(collectorPhoto, recyclerPhoto)
                if (!photosValid) return HandoverVerificationResult.PhotoVerificationFailed
                
                // 7. Create traceability record
                val traceId = UUID.randomUUID().toString()
                val traceability = TraceabilityEntity(
                    traceId = traceId,
                    lotId = payload.lot_id,
                    handoverQrHash = QRHash(qrData),
                    edgeTimestamp = System.currentTimeMillis(),
                    handoverLat = collectorLocation.lat,
                    handoverLon = collectorLocation.lon,
                    handoverPhotoUri = collectorPhoto.uri,
                    recyclerSignPubkey = recyclerPublicKey,
                    verificationStatus = "pending"
                )
                traceabilityDao.upsert(traceability)
                
                // 8. Update transaction
                transactionDao.updateStatus(payload.tx_id, "verified")
                
                // 9. Send notification to collector
                notificationService.notifyHandoverVerified(payload.tx_id)
                
                return HandoverVerificationResult.Success(payload.tx_id, payload.price.net_offered_price_inr)
            }
            
            VerificationResult.Expired -> HandoverVerificationResult.Expired
            VerificationResult.InvalidSignature -> HandoverVerificationResult.InvalidSignature
            is VerificationResult.Error -> HandoverVerificationResult.Error(verificationResult.message)
        }
    }
}

sealed class HandoverVerificationResult {
    data class Success(val txId: String, val settlementAmount: Double) : HandoverVerificationResult()
    object Expired : HandoverVerificationResult()
    object InvalidSignature : HandoverVerificationResult()
    object PhotoVerificationFailed : HandoverVerificationResult()
    data class Error(val message: String) : HandoverVerificationResult()
}
```

---

## 8. Security Considerations

### 8.1 Key Management

| Security Measure | Implementation |
|------------------|----------------|
| **Key Storage** | Android Keystore (hardware-backed) |
| **Key Rotation** | New key pair per transaction |
| **Key Lifetime** | 24 hours max |
| **Backup** | None (keys destroyed after verification) |

### 8.2 QR Code Security

| Feature | Implementation |
|---------|----------------|
| **Signing** | ECDSA secp256r1 |
| **Expiration** | 24 hours |
| **One-time use** | Check transaction state before verification |
| **Tamper detection** | Signature verification required |

### 8.3 Replay Attack Prevention

1. **Timestamp checking**: QR codes expire after 24 hours
2. **Transaction state tracking**: Each QR can only be used once
3. **Location verification**: Photos must be taken at handover location

---

## 9. Performance Targets

| Metric | Target |
|--------|--------|
| QR Generation | <50ms |
| QR Scanning | <200ms |
| Signature Verification | <30ms |
| Handover Complete | <5 seconds |

---

## 10. Testing

### 10.1 Unit Tests

```kotlin
@Test
fun testQRSignatureVerification() = runTest {
    val keyPair = generateECDSAKeyPair()
    val qrData = signQRData(...)
    
    val result = verifyQRSignature(qrData, keyPair.publicKey)
    
    assertTrue(result is VerificationResult.Valid)
}
```

### 10.2 Integration Tests

- Generate QR code, scan with another device, verify signature
- Test expired QR code rejection
- Test signature tampering detection

---

## 11. References

1. [ECDSA Security](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.186-5.pdf)
2. [QR Code Specification](https://www.iso.org/standard/62021.html)
3. [Android Keystore](https://developer.android.com/training/articles/keystore)

---

**Status:** ✅ Approved for Implementation  
**Next Step:** QR Code Generation and Verification Module