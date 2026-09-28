# 00 — System Architecture
## Kabadiwala Connect · SIH 2026 · Problem Statement 26229
### Ministry of Mines / JNARDDC · Clean & Green Technology

---

## 1. Problem Framing (From PS 26229)

India generates **3.23 million tonnes** of e-waste per year (3rd largest globally). The informal sector — kabadiwalas, itinerant waste-pickers, aggregators — collects **~95 %** of it, yet earns far below fair value and cannot access CPCB EPR certificates. Unsafe backyard processing (open-air cable burning, acid leaching of PCBs) destroys critical minerals (Li, Co, Nd, Ta, Ga, In) that NCMM values at ₹1,500 crore+ in its 2025–2031 recycling scheme.

**Root causes to solve:**
1. **Price opacity** — collector doesn't know the EPR-augmented fair price
2. **No digital identity** — can't participate in formal EPR chain without traceable records
3. **Literacy/language barrier** — English-only apps fail in the field
4. **Connectivity gaps** — intermittent 2G/offline in collection routes
5. **No formal handover record** — recycler can't issue compliant EPR certificate without documented transfer

---

## 2. Why Flutter (Not Native Android)

| Criterion | Native Android (Kotlin) | **Flutter (Dart)** ← chosen |
|---|---|---|
| Collector app | ✓ | ✓ |
| Recycler web dashboard | ✗ needs separate PWA | ✓ same codebase → Web |
| Admin panel | ✗ | ✓ Flutter Web |
| Demo at SIH across platforms | Risk | Single codebase demo |
| TFLite support | `tflite_flutter` equivalent | ✓ `tflite_flutter` plugin |
| Bhashini / HTTP | Retrofit | ✓ `dio` + Bhashini REST |
| Team velocity (hackathon) | Slower (2 codebases) | **Faster** |

**Decision:** One Flutter codebase targets Android (collector + recycler), Web (admin panel), and demo kiosk.

---

## 3. High-Level Component Map

```
╔══════════════════════════════════════════════════════════════════════╗
║                    KABADIWALA CONNECT SYSTEM                        ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║  ┌─────────────────────────────────────────────────────────────┐   ║
║  │              FLUTTER MOBILE APP  (Android ≥ 6.0)            │   ║
║  │                                                              │   ║
║  │  Collector Mode             │  Recycler Mode                │   ║
║  │  ─────────────              │  ─────────────                │   ║
║  │  • Camera scan (TFLite)     │  • QR scan & verify           │   ║
║  │  • Voice input (Bhashini)   │  • Dual-custody photo         │   ║
║  │  • Price board (offline)    │  • Confirm weight / payment   │   ║
║  │  • Lot creation             │  • Handover ledger            │   ║
║  │  • QR generation (ECDSA)    │  • EPR cert trigger           │   ║
║  │  • Earnings ledger          │  • Recycler dashboard         │   ║
║  │  • Safety guide (audio)     │                               │   ║
║  │                                                              │   ║
║  │  ┌─────────────────────────────────────────────────────┐   │   ║
║  │  │  LOCAL LAYER (Offline-First)                        │   │   ║
║  │  │  SQLite / Drift ORM · Outbox table · Shared Prefs  │   │   ║
║  │  │  TFLite model (4.2 MB bundled) · Audio cache        │   │   ║
║  │  └──────────────────────┬──────────────────────────────┘   │   ║
║  └─────────────────────────┼────────────────────────────────────┘   ║
║                             │ HTTPS + Protobuf (WorkManager sync)   ║
║                             ▼                                        ║
║  ┌─────────────────────────────────────────────────────────────┐   ║
║  │                  BACKEND SERVICES (Rust / Axum)              │   ║
║  │                                                              │   ║
║  │  /auth    /collectors   /recyclers   /prices   /sync        │   ║
║  │  /materials   /transactions   /traceability   /admin        │   ║
║  │                                                              │   ║
║  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │   ║
║  │  │  PostgreSQL  │  │  Redis cache │  │  S3 photo store  │  │   ║
║  │  │  (primary)   │  │  (prices)    │  │  (handover pics) │  │   ║
║  │  └──────────────┘  └──────────────┘  └──────────────────┘  │   ║
║  └─────────────────────────────────────────────────────────────┘   ║
║                             │                                        ║
║  ┌─────────────────────────────────────────────────────────────┐   ║
║  │            EXTERNAL INTEGRATIONS                             │   ║
║  │  Bhashini Dhruva API  ·  CPCB EPR Portal  ·  NCMM Feed     │   ║
║  │  UPI deep-link (PhonePe/BHIM)  ·  SMS OTP (MSG91)          │   ║
║  └─────────────────────────────────────────────────────────────┘   ║
╚══════════════════════════════════════════════════════════════════════╝
```

---

## 4. Flutter App Architecture — Clean Architecture + Riverpod

```
lib/
├── core/
│   ├── constants/         # app_colors, app_strings, app_routes
│   ├── error/             # failures.dart, exceptions.dart
│   ├── network/           # dio_client.dart, connectivity_service.dart
│   ├── storage/           # drift_database.dart, secure_storage.dart
│   └── utils/             # qr_signer.dart, density_calc.dart, bhashini_client.dart
│
├── features/
│   ├── auth/
│   │   ├── data/          # auth_repo_impl, auth_datasource
│   │   ├── domain/        # auth_repo (abstract), use_cases
│   │   └── presentation/  # login_screen, otp_screen, providers
│   │
│   ├── scanner/           # CV material scan + weight entry
│   ├── price_board/       # Price discovery + history chart
│   ├── lot_creation/      # Lot confirm + QR generate
│   ├── handover/          # QR scan + dual-custody photo (Recycler)
│   ├── earnings/          # Ledger + payment history
│   ├── safety/            # Pictorial/audio safety guide
│   ├── recycler_dash/     # Recycler pending handovers + analytics
│   └── onboarding/        # Language picker + walkthrough
│
└── l10n/                  # app_hi.arb, app_mr.arb, app_en.arb
```

**State management:** Riverpod 2.x (AsyncNotifierProvider for async ops, NotifierProvider for UI state)  
**Navigation:** GoRouter 14.x (deep-links for QR tap-to-open, notification routes)  
**Local DB:** Drift (type-safe SQLite wrapper with DAOs)  
**HTTP:** Dio with interceptors (auth token, retry, offline queue)  
**Background sync:** `workmanager` Flutter plugin → native WorkManager

---

## 5. Data Flow — End-to-End Material Lifecycle

```
1. COLLECTION
   Collector opens app → Camera → TFLite infers class + bounding box
   → Weight entered (voice or keypad) → Density fraud check (local)
   → Price looked up from local cache → Lot created in Drift DB
   → Outbox entry written in same transaction

2. LOT READY
   Lot confirmed → ECDSA key pair generated per transaction
   → QR code signed with collector private key
   → QR displayed on screen (collector device)

3. HANDOVER
   Recycler scans QR → Signature verified with collector public key
   → Dual-custody photos captured (collector + recycler cameras)
   → Traceability record written in Drift DB
   → Transaction status updated to VERIFIED

4. SYNC (online)
   WorkManager triggers SyncWorker when network available
   → Pending outbox records serialised to Protobuf (45-65% size reduction)
   → POST /api/v1/sync with X-Idempotency-Key header
   → Backend processes idempotently, returns server timestamp
   → Outbox entries marked SYNCED

5. EPR CERTIFICATE
   Backend triggers EPR cert generation on CPCB portal after verified handover
   → Cert ID stored against transaction record
   → NCMM critical mineral tracking updated (Co, Li, Nd content estimate)

6. PAYMENT
   Recycler initiates UPI payment or marks cash paid
   → Transaction COMPLETED in both Drift DB (local) and backend
   → Collector earnings ledger updated
   → Push notification to collector (FCM)
```

---

## 6. Technology Decisions Table

| Component | Choice | Version | Reason |
|-----------|--------|---------|--------|
| Mobile UI | Flutter | 3.24 | Cross-platform (Android + Web), single codebase |
| State | Riverpod | 2.5 | Compile-safe, testable, no BuildContext dependency |
| Navigation | GoRouter | 14.2 | Deep links for QR, named routes |
| Local DB | Drift | 2.18 | Type-safe SQLite, DAOs, migrations, stream support |
| HTTP client | Dio | 5.7 | Interceptors, retry, Protobuf response |
| Background sync | workmanager | 0.5.7 | Native WorkManager on Android |
| Edge AI | tflite_flutter | 0.10.4 | YOLOv8-Nano INT8, NNAPI backend |
| Camera | camera | 0.11 | CameraX, image stream for inference |
| QR generate | qr_flutter | 4.1 | Fast bitmap generation |
| QR scan | mobile_scanner | 5.2 | ML Kit barcode scanning |
| Crypto (ECDSA) | pointycastle | 3.7 | Pure Dart ECDSA secp256r1 |
| Voice (STT/TTS) | Custom Bhashini client | — | Dhruva pipeline REST API |
| Audio record | flutter_sound | 9.2 | WAV 16kHz mono recording |
| Audio play | just_audio | 0.9 | Low-latency TTS playback |
| Localisation | flutter_localizations | SDK | ARB files for hi, mr, en |
| Secure storage | flutter_secure_storage | 9.2 | Keys in Keystore/Keychain |
| Connectivity | connectivity_plus | 6.1 | Sync trigger on network restore |
| Images | cached_network_image | 3.4 | Offline photo caching |
| Push | firebase_messaging | 15.1 | Recycler handover alerts |
| Charts | fl_chart | 0.68 | Price trend graph |
| PDF | pdf | 3.11 | Handover receipt PDF |
| Protobuf | protobuf | 3.1 | Sync payload serialisation |

---

## 7. Offline-First Data Strategy

| Data Type | Storage Location | Sync Direction | Conflict Resolution |
|-----------|-----------------|----------------|---------------------|
| Collector profile | Drift (local-only) | Up on first login | N/A |
| Price feed | Drift (cached 24h) | Down (server → client) | Server wins |
| Recycler registry | Drift (cached 7d) | Down | Server wins |
| Material lots | Drift → Outbox | Up (client → server) | Client immutable |
| Transactions | Drift → Outbox | Bidirectional | Server state wins |
| Traceability chain | Drift → Outbox | Up | Append-only |
| Handover photos | Device files → S3 | Up (background) | Deduplication by SHA-256 |
| Safety guide content | Bundled assets | None | App update |
| AI model | Bundled assets | OTA update (on WiFi) | Versioned |

---

## 8. Security Architecture

```
Authentication:   Phone OTP → JWT RS256 (access 1h, refresh 30d)
                  Stored in FlutterSecureStorage (Keystore-backed)

Transport:        TLS 1.3 with certificate pinning (dio_certificate_pinning)
                  Bhashini calls use separate API key, stored encrypted

QR Handover:      ECDSA secp256r1 per-transaction key pair
                  Private key: generated fresh, never persisted after sign
                  Public key: included in QR payload for recycler verification

Database:         SQLCipher via drift (encrypted SQLite)

Photos:           SHA-256 hash verified before upload
                  Exif GPS stripped before display (privacy)

Privacy:          No real phone number stored on device (SHA-256 hash)
                  No biometric data collected
                  Collector ID is opaque hash, not linkable to name
```

---

## 9. Performance Targets (Entry-Level Device: Redmi 9 / 3 GB RAM / Android 10)

| Metric | Target | Measurement method |
|--------|--------|--------------------|
| Cold app launch | < 3 s | Systrace cold start |
| TFLite inference (CPU) | < 120 ms | Stopwatch in InferenceService |
| TFLite inference (NNAPI) | < 60 ms | Stopwatch in InferenceService |
| QR generation | < 50 ms | Stopwatch in QRService |
| QR verification (ECDSA) | < 30 ms | Stopwatch in HandoverService |
| Price board load (offline) | < 100 ms | Drift query profiling |
| Bhashini STT round-trip | < 4 s | Network timing |
| Bhashini TTS playback start | < 2 s | Audio latency |
| Sync batch (50 records) | < 8 s on 3G | WorkManager timing |
| APK size | < 30 MB | flutter build apk --analyze-size |

---

## 10. SIH Judging Criteria Mapping

| Criterion | Weight | How This Architecture Addresses It |
|-----------|--------|-------------------------------------|
| **Problem Understanding** | 20% | EPR Rules 2022 compliance, NCMM integration, informal sector data from academic research cited |
| **Innovation** | 20% | ECDSA dual-custody QR, density fraud detection, voice-first vernacular UX |
| **Technical Soundness** | 20% | Offline-first Drift DB, Transactional Outbox, TFLite NNAPI, ECDSA |
| **Usability** | 15% | Bhashini voice, pictorial UI, Hindi/Marathi, large touch targets |
| **Field Research** | 15% | 2 collector interviews documented in spec 12, GPS-tracked routes |
| **Economic Sustainability** | 10% | Unit economics in spec 11, platform fee model, NCMM incentive sharing |

---

## 11. Deployment Plan (Hackathon Demo)

```
Day 1-2:   Flutter project scaffold + Drift schema + Riverpod providers
Day 3-4:   TFLite integration + Camera + Price board (offline)
Day 5-6:   Bhashini voice interface + Lot creation flow
Day 7:     ECDSA QR generation + Recycler scan + dual-custody photos
Day 8:     Sync worker + Outbox + mock backend (JSON server)
Day 9:     Recycler dashboard (Flutter Web) + Earnings ledger + Safety screen
Day 10:    Polish UI, Hindi/Marathi strings, field test, demo rehearsal
```

---

## 12. References

1. E-Waste (Management) Rules 2022 — MoEFCC / CPCB  
2. NCMM ₹1,500 Cr Recycling Incentive Scheme — Ministry of Mines, Sep 2025  
3. Sengupta et al. (2022) — *Circular economy and household e-waste management in India* — Monash University  
4. Bhashini Dhruva API Docs — https://bhashini.gitbook.io/bhashini-apis/  
5. CPCB EPR Certificate Floor Price Guidelines  
6. YOLOv8 — Ultralytics (2023)  
7. Drift ORM — https://drift.simonbinder.eu/
