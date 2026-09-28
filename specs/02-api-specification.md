# Kabadiwala Connect - API Specification

**Version:** 1.0.0  
**Date:** September 28, 2026  
**API Style:** RESTful JSON  
**Authentication:** JWT Bearer Token  
**Status:** Draft - Ready for Backend Implementation

---

## 1. Overview

This specification defines the RESTful API for Kabadiwala Connect backend services, covering collector, recycler, and admin endpoints.

---

## 2. Base Configuration

```
Base URL (Production): https://api.kabadiwalaconnect.in
Base URL (Staging): https://staging-api.kabadiwalaconnect.in
Base URL (Development): http://localhost:8080

API Version: v1
Media Type: application/json
Character Set: UTF-8
```

---

## 3. Authentication

### 3.1 JWT Token Format

```
Header: {
  "alg": "RS256",
  "typ": "JWT"
}

Payload: {
  "sub": "collector_id_or_recycler_id",
  "role": "collector|recycler|admin",
  "phone": "+919876543210",
  "iat": 1695897600,
  "exp": 1695984000
}
```

### 3.2 Authentication Flow

```
POST /api/v1/auth/login
  Request: { "phone": "+919876543210" }
  Response: 200 OK, { "otp_reference": "uuid-uuid-uuid" }

POST /api/v1/auth/verify-otp
  Request: { "otp_reference": "uuid", "otp": "123456" }
  Response: 200 OK, { "access_token": "jwt...", "refresh_token": "jwt..." }

POST /api/v1/auth/refresh
  Request: { "refresh_token": "jwt..." }
  Response: 200 OK, { "access_token": "jwt..." }
```

### 3.3 Protected Endpoints

All endpoints except `/api/v1/auth/*` require:

```
Authorization: Bearer <access_token>
```

---

## 4. Error Responses

### 4.1 Standard Error Format

```json
{
  "error": {
    "code": "ERR_001",
    "message": "Invalid authentication token",
    "details": "Token has expired",
    "timestamp": "2026-09-28T10:30:00Z"
  }
}
```

### 4.2 Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `ERR_001` | 401 | Authentication failed |
| `ERR_002` | 403 | Authorization denied |
| `ERR_003` | 400 | Invalid request body |
| `ERR_004` | 404 | Resource not found |
| `ERR_005` | 409 | Conflict (duplicate) |
| `ERR_006` | 429 | Rate limit exceeded |
| `ERR_007` | 500 | Internal server error |
| `ERR_008` | 503 | Service unavailable |

---

## 5. Collector Endpoints

### 5.1 Profile Management

#### 5.1.1 Register Collector

```
POST /api/v1/collectors/register
```

**Request:**
```json
{
  "phone": "+919876543210",
  "preferred_lang": "hi",
  "operating_zone": "110001"
}
```

**Response (201 Created):**
```json
{
  "collector_id": "sha256_hash_of_phone",
  "phone_mask": "98****1234",
  "otp_reference": "uuid-uuid-uuid",
  "message": "OTP sent to +919876543210"
}
```

**Errors:**
- `ERR_005`: Phone already registered

---

#### 5.1.2 Get Collector Profile

```
GET /api/v1/collectors/profile
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "collector_id": "sha256_hash_of_phone",
  "phone_mask": "98****1234",
  "preferred_lang": "hi",
  "operating_zone": "110001",
  "operating_zone_name": "New Delhi",
  "cumulative_tons": 25.5,
  "lifetime_earnings": 12500.00,
  "is_active": true,
  "created_at": "2026-08-15T08:00:00Z"
}
```

---

#### 5.1.3 Update Collector Profile

```
PUT /api/v1/collectors/profile
Authorization: Bearer <token>
```

**Request:**
```json
{
  "preferred_lang": "mr",
  "operating_zone": "400001"
}
```

**Response (200 OK):**
```json
{
  "collector_id": "sha256_hash_of_phone",
  "preferred_lang": "mr",
  "operating_zone": "400001"
}
```

---

### 5.2 Material Registration

#### 5.2.1 Register New Material Lot

```
POST /api/v1/materials
Authorization: Bearer <token>
```

**Request:**
```json
{
  "category": "electronics",
  "sub_category": "pcb",
  "condition_grade": "B",
  "est_weight_kg": 2.5,
  "est_valuation_inr": 250.0,
  "image_edge_hash": "sha256_hex_string...",
  "bounding_box_json": [100, 150, 300, 200],
  "inferred_class": "pcb",
  "density_inferred_kg_m3": 1800.5,
  "lat": 28.7041,
  "lon": 77.1025,
  "schedule_code": "SCHED-2026-09-28-001"
}
```

**Response (201 Created):**
```json
{
  "lot_id": "uuid-uuid-uuid",
  "collector_id": "sha256_hash",
  "schedule_code": "SCHED-2026-09-28-001",
  "category": "electronics",
  "sub_category": "pcb",
  "est_weight_kg": 2.5,
  "est_valuation_inr": 250.0,
  "created_at": "2026-09-28T10:30:00Z"
}
```

---

#### 5.2.2 Get Material History

```
GET /api/v1/materials?limit=20&offset=0
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "items": [
    {
      "lot_id": "uuid-uuid-uuid",
      "category": "electronics",
      "sub_category": "pcb",
      "condition_grade": "B",
      "est_weight_kg": 2.5,
      "est_valuation_inr": 250.0,
      "created_at": "2026-09-28T10:30:00Z",
      "tx_lifecycle_state": "pending"
    }
  ],
  "total_count": 45,
  "limit": 20,
  "offset": 0
}
```

---

#### 5.2.3 Update Material Status

```
PATCH /api/v1/materials/{lot_id}
Authorization: Bearer <token>
```

**Request:**
```json
{
  "status": "flagged_fraud",
  "fraud_reason": "Suspicious density: 5000 kg/m³ for plastic"
}
```

**Response (200 OK):**
```json
{
  "lot_id": "uuid-uuid-uuid",
  "is_fraud_flagged": true,
  "fraud_reason": "Suspicious density: 5000 kg/m³ for plastic"
}
```

---

### 5.3 Price Discovery

#### 5.3.1 Get Current Price Feed

```
GET /api/v1/prices?sub_category=pcb&region_code=110001
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "price_record_id": "uuid",
  "sub_category": "pcb",
  "geo_region_code": "110001",
  "geo_region_name": "New Delhi",
  "informal_base_rate": 80.0,
  "formal_gate_rate": 120.0,
  "epr_credit_share": 33.60,
  "ncmm_incentive": 5.0,
  "net_offered_price": 158.60,
  "source": "cpcb",
  "effective_from": "2026-09-01T00:00:00Z",
  "effective_to": "2026-09-30T23:59:59Z",
  "last_updated": "2026-09-25T12:00:00Z"
}
```

---

#### 5.3.2 Get Price History

```
GET /api/v1/prices/history?sub_category=pcb&start_date=2026-09-01&end_date=2026-09-30
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "sub_category": "pcb",
  "prices": [
    {
      "date": "2026-09-01",
      "net_offered_price": 155.00,
      "source": "cpcb"
    },
    {
      "date": "2026-09-15",
      "net_offered_price": 158.60,
      "source": "cpcb"
    },
    {
      "date": "2026-09-30",
      "net_offered_price": 158.60,
      "source": "local"
    }
  ]
}
```

---

### 5.4 Transaction Management

#### 5.4.1 Get Transaction History

```
GET /api/v1/transactions?limit=20&offset=0
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "items": [
    {
      "tx_id": "uuid-uuid-uuid",
      "lot_id": "uuid-uuid-uuid",
      "quoted_value_inr": 250.0,
      "final_settled_inr": 240.0,
      "settlement_mode": "upi",
      "tx_lifecycle_state": "completed",
      "recycler_id": "uuid-uuid-uuid",
      "quote_timestamp": "2026-09-28T10:30:00Z",
      "settlement_timestamp": "2026-09-28T11:00:00Z"
    }
  ],
  "total_count": 45,
  "limit": 20,
  "offset": 0
}
```

---

#### 5.4.2 Get Transaction by Lot

```
GET /api/v1/transactions/lot/{lot_id}
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "tx_id": "uuid-uuid-uuid",
  "lot_id": "uuid-uuid-uuid",
  "quoted_value_inr": 250.0,
  "final_settled_inr": 240.0,
  "settlement_mode": "upi",
  "tx_lifecycle_state": "completed",
  "recycler_id": "uuid-uuid-uuid",
  "payment_reference": "12345678901234",
  "quote_timestamp": "2026-09-28T10:30:00Z",
  "settlement_timestamp": "2026-09-28T11:00:00Z"
}
```

---

## 6. Recycler Endpoints

### 6.1 Profile Management

#### 6.1.1 Get Recycler Profile

```
GET /api/v1/recyclers/profile
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "recycler_id": "uuid-uuid-uuid",
  "legal_entity_name": "GreenTech Recyclers Pvt Ltd",
  "cpcb_reg_number": "CPCB/DEL/2026/12345",
  "facility_lat": 28.7041,
  "facility_lon": 77.1025,
  "facility_address": "Plot No. 123, Industrial Area, New Delhi",
  "accepted_classes": ["electronics", "plastic", "metal"],
  "logistics_capability": "pickup",
  "verification_status": "verified",
  "avg_payment_time_hours": 24.0,
  "rating": 4.5,
  "total_handovers": 150
}
```

---

### 6.2 Handover Management

#### 6.2.1 Get Pending Handovers

```
GET /api/v1/recyclers/handovers/pending?limit=20&offset=0
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "items": [
    {
      "trace_id": "uuid-uuid-uuid",
      "lot_id": "uuid-uuid-uuid",
      "collector_id": "sha256_hash",
      "collector_phone_mask": "98****1234",
      "handover_qr_hash": "sha256...",
      "handover_timestamp": "2026-09-28T10:30:00Z",
      "handover_lat": 28.7041,
      "handover_lon": 77.1025,
      "verification_status": "pending",
      "materials": {
        "category": "electronics",
        "sub_category": "pcb",
        "est_weight_kg": 2.5,
        "est_valuation_inr": 250.0
      }
    }
  ],
  "total_count": 12,
  "limit": 20,
  "offset": 0
}
```

---

#### 6.2.2 Verify Handover

```
POST /api/v1/recyclers/handovers/{trace_id}/verify
Authorization: Bearer <token>
```

**Request:**
```json
{
  "recycler_sign_pubkey": "base64_encoded_public_key...",
  "recycler_signature": "base64_encoded_signature...",
  "verified_lat": 28.7042,
  "verified_lon": 77.1026,
  "photos": [
    "base64_encoded_photo_1...",
    "base64_encoded_photo_2..."
  ]
}
```

**Response (200 OK):**
```json
{
  "trace_id": "uuid-uuid-uuid",
  "verification_status": "verified",
  "verified_timestamp": "2026-09-28T10:35:00Z",
  "transaction_id": "uuid-uuid-uuid",
  "final_settled_inr": 396.50,
  "message": "Handover verified. Payment will be processed within 24 hours."
}
```

---

#### 6.2.3 Reject Handover

```
POST /api/v1/recyclers/handovers/{trace_id}/reject
Authorization: Bearer <token>
```

**Request:**
```json
{
  "rejection_reason": "Condition grade mismatch: Expected grade B, found grade D",
  "photos": ["base64_photo..."]
}
```

**Response (200 OK):**
```json
{
  "trace_id": "uuid-uuid-uuid",
  "verification_status": "rejected",
  "rejection_reason": "Condition grade mismatch: Expected grade B, found grade D"
}
```

---

#### 6.2.4 Submit Payment Confirmation

```
POST /api/v1/recyclers/handovers/{trace_id}/payment
Authorization: Bearer <token>
```

**Request:**
```json
{
  "final_settled_inr": 396.50,
  "settlement_mode": "upi",
  "payment_reference": "12345678901234",
  "payment_timestamp": "2026-09-28T11:00:00Z"
}
```

**Response (200 OK):**
```json
{
  "tx_id": "uuid-uuid-uuid",
  "final_settled_inr": 396.50,
  "settlement_mode": "upi",
  "payment_reference": "12345678901234",
  "tx_lifecycle_state": "completed"
}
```

---

### 6.3 Price Discovery

#### 6.3.1 Get Recycler Price Feed

```
GET /api/v1/recyclers/prices?accepted_classes=electronics,plastic
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "recycler_id": "uuid-uuid-uuid",
  "prices": [
    {
      "sub_category": "pcb",
      "net_offered_price": 158.60,
      "informal_base_rate": 80.0,
      "epr_credit_share": 33.60,
      "ncmm_incentive": 5.0,
      "margin": 45.0
    },
    {
      "sub_category": "plastic_pet",
      "net_offered_price": 45.00,
      "informal_base_rate": 25.0,
      "epr_credit_share": 10.0,
      "ncmm_incentive": 0.0,
      "margin": 10.0
    }
  ]
}
```

---

## 7. Admin Endpoints

### 7.1 Recycler Verification

#### 7.1.1 Get Pending Recyclers

```
GET /api/v1/admin/recyclers/pending
Authorization: Bearer <admin_token>
```

**Response (200 OK):**
```json
{
  "items": [
    {
      "recycler_id": "uuid-uuid-uuid",
      "legal_entity_name": "GreenTech Recyclers Pvt Ltd",
      "cpcb_reg_number": "CPCB/DEL/2026/12345",
      "facility_address": "Plot No. 123, Industrial Area, New Delhi",
      "verification_status": "pending",
      "created_at": "2026-09-20T10:00:00Z"
    }
  ]
}
```

---

#### 7.1.2 Verify Recycler

```
POST /api/v1/admin/recyclers/{recycler_id}/verify
Authorization: Bearer <admin_token>
```

**Request:**
```json
{
  "verified_by": "admin_id",
  "notes": "Documents verified, facility inspected on 2026-09-25"
}
```

**Response (200 OK):**
```json
{
  "recycler_id": "uuid-uuid-uuid",
  "verification_status": "verified",
  "verified_timestamp": "2026-09-28T10:30:00Z",
  "verified_by": "admin_id"
}
```

---

#### 7.1.3 Reject Recycler

```
POST /api/v1/admin/recyclers/{recycler_id}/reject
Authorization: Bearer <admin_token>
```

**Request:**
```json
{
  "rejection_reason": "Incomplete documentation: Missing CPCB renewal certificate",
  "rejection_notes": "Please resubmit with updated documents"
}
```

**Response (200 OK):**
```json
{
  "recycler_id": "uuid-uuid-uuid",
  "verification_status": "rejected",
  "rejection_reason": "Incomplete documentation: Missing CPCB renewal certificate",
  "rejection_timestamp": "2026-09-28T10:30:00Z"
}
```

---

### 7.2 Price Management

#### 7.2.1 Set Price Feed

```
POST /api/v1/admin/prices
Authorization: Bearer <admin_token>
```

**Request:**
```json
{
  "sub_category": "pcb",
  "geo_region_code": "110001",
  "informal_base_rate": 80.0,
  "formal_gate_rate": 120.0,
  "epr_credit_share": 33.60,
  "ncmm_incentive": 5.0,
  "effective_from": "2026-09-01T00:00:00Z",
  "effective_to": "2026-09-30T23:59:59Z"
}
```

**Response (201 Created):**
```json
{
  "price_record_id": "uuid-uuid-uuid",
  "sub_category": "pcb",
  "geo_region_code": "110001",
  "net_offered_price": 158.60,
  "effective_from": "2026-09-01T00:00:00Z",
  "effective_to": "2026-09-30T23:59:59Z"
}
```

---

#### 7.2.2 Bulk Price Import

```
POST /api/v1/admin/prices/bulk
Authorization: Bearer <admin_token>
Content-Type: multipart/form-data
```

**Request:**
```
File: prices.csv

sub_category,geo_region_code,informal_base_rate,formal_gate_rate,epr_credit_share,ncmm_incentive,effective_from,effective_to
pcb,110001,80.0,120.0,33.60,5.0,2026-09-01,2026-09-30
plastic_pet,110001,25.0,40.0,10.0,0.0,2026-09-01,2026-09-30
```

**Response (200 OK):**
```json
{
  "processed": 150,
  "success": 148,
  "failed": 2,
  "failures": [
    {
      "row": 5,
      "error": "Invalid date format"
    },
    {
      "row": 25,
      "error": "Unknown sub_category: invalid_material"
    }
  ]
}
```

---

### 7.3 Analytics

#### 7.3.1 Get Platform Analytics

```
GET /api/v1/admin/analytics?start_date=2026-09-01&end_date=2026-09-30
Authorization: Bearer <admin_token>
```

**Response (200 OK):**
```json
{
  "period": {
    "start": "2026-09-01",
    "end": "2026-09-30"
  },
  "collectors": {
    "total": 1250,
    "active_30d": 450,
    "new_30d": 75
  },
  "materials": {
    "total_lots": 3500,
    "total_weight_kg": 8500.0,
    "total_value_inr": 1275000.0
  },
  "recyclers": {
    "total": 45,
    "verified": 38,
    "pending_verification": 7
  },
  "transactions": {
    "total": 2800,
    "completed": 2650,
    "pending": 150,
    "total_volume_inr": 1150000.0
  },
  "fraud_detection": {
    "flagged": 25,
    "confirmed_fraud": 5,
    "false_positives": 20
  }
}
```

---

## 8. Sync Protocol (Transactional Outbox)

### 8.1 Sync Endpoint

```
POST /api/v1/sync
Authorization: Bearer <token>
Content-Type: application/x-protobuf
X-Idempotency-Key: <uuid>
```

**Request (Protobuf):**
```protobuf
message SyncRequest {
  string collector_id = 1;
  repeated Material materials = 2;
  repeated Transaction transactions = 3;
  repeated Traceability traceabilities = 4;
  int64 client_timestamp = 5;
  string sync_id = 6;
}
```

**Response (200 OK):**
```json
{
  "sync_id": "uuid-uuid-uuid",
  "server_timestamp": 1695897600,
  "processed": {
    "materials": 10,
    "transactions": 5,
    "traceabilities": 3
  },
  "errors": []
}
```

---

## 9. WebSocket Events (Real-time)

### 9.1 Connection

```
ws://api.kabadiwalaconnect.in/ws?token=<jwt_token>
```

### 9.2 Events

#### Payment Notification

```json
{
  "event": "payment_complete",
  "data": {
    "tx_id": "uuid-uuid-uuid",
    "amount": 396.50,
    "collector_id": "sha256_hash"
  }
}
```

#### New Handover Alert

```json
{
  "event": "new_handover",
  "data": {
    "trace_id": "uuid-uuid-uuid",
    "lot_id": "uuid-uuid-uuid",
    "collector_id": "sha256_hash",
    "timestamp": "2026-09-28T10:30:00Z"
  }
}
```

---

## 10. Rate Limiting

| Endpoint | Limit | Window |
|----------|-------|--------|
| `/api/v1/auth/*` | 5 requests/minute | per phone |
| `/api/v1/materials` | 30 requests/minute | per user |
| `/api/v1/prices` | 60 requests/minute | per user |
| `/api/v1/sync` | 10 requests/minute | per user |

**Headers:**
```
X-RateLimit-Limit: 30
X-RateLimit-Remaining: 28
X-RateLimit-Reset: 1695897660
```

---

## 11. Testing

### 11.1 Postman Collection

- Available at: `specs/postman/kabadiwala-connect.postman_collection.json`
- Includes: All endpoints, authentication flow, sample requests

### 11.2 Test Accounts

| Phone | Role | OTP |
|-------|------|-----|
| +919876543210 | Collector | 123456 |
| +919876543211 | Recycler | 123456 |
| +919876543212 | Admin | 123456 |

---

## 12. Versioning

- API versioning in URL: `/api/v1/...`
- Breaking changes: Major version bump (`v2`)
- Non-breaking changes: Minor version bump (`v1.1`)

---

## 13. References

1. [RESTful API Best Practices](https://restfulapi.net/)
2. [JWT RFC 7519](https://tools.ietf.org/html/rfc7519)
3. [OpenAPI Specification](https://swagger.io/specification/)

---

**Status:** ✅ Approved for Implementation  
**Next Step:** Backend API Implementation in Rust/Axum