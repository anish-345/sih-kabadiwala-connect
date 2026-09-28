import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/core/storage/database.dart';
import 'package:kabadiwala_connect/core/storage/models.dart';
import 'package:kabadiwala_connect/core/utils/density_fraud_detector.dart';
import 'package:kabadiwala_connect/core/utils/qr_signer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Core Operations & Data Integrity (PS 26229)', () {
    late AppDatabase db;

    setUp(() async {
      db = await AppDatabase.create(inMemory: true);
    });

    tearDown(() {
      db.close();
    });

    test('1. Direct Seed & Price Feed Query with living e-waste categories', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      // Seed a realistic price record for PCB Class A
      final pcbPrice = PriceFeedData(
        priceRecordId: 'PRICE_PCBA_PUNE_2026',
        category: 'pcb_telecom',
        subCategory: 'Telecom / Server Grade Gold Plated',
        geoRegionCode: 'IN-MH-PUNE',
        informalBaseRate: 280.0,
        formalGateRate: 460.0,
        eprCreditShare: 35.0,
        ncmmIncentive: 15.0,
        netOfferedPrice: 510.0,
        trend: 'UP',
        trendDeltaPercent: 4.8,
        trendHistory: [485.0, 490.0, 495.0, 500.0, 505.0, 510.0, 510.0],
        hazardType: 'LOW',
        source: 'CPCB / JNARDDC Official Bulletin',
        effectiveFrom: now - 86400000 * 7,
        effectiveTo: now + 86400000 * 7,
        notes: 'High gold contact density. NCMM strategic critical metals bonus applicable.',
      );

      db.insertPrice(pcbPrice);

      final prices = db.getAllPrices();
      expect(prices.length, greaterThanOrEqualTo(11));
      final fetched = prices.firstWhere((p) => p.priceRecordId == 'PRICE_PCBA_PUNE_2026');
      expect(fetched.category, 'pcb_telecom');
      expect(fetched.informalBaseRate, 280.0);
      expect(fetched.netOfferedPrice, 510.0);

      // Verify net worker benefit calculation:
      // Informal scrap dealer pays Rs. 280/kg. Platform delivers Rs. 510/kg.
      final workerGainPercent = ((fetched.netOfferedPrice - fetched.informalBaseRate) / fetched.informalBaseRate) * 100;
      expect(workerGainPercent, closeTo(82.14, 0.05));
    });

    test('2. Recycler ranking and matching based on accepted classes and bonuses', () {
      const recycler1 = RecyclerData(
        recyclerId: 'REC_ECORECO_01',
        legalEntityName: 'Eco Recycling Ltd (Ecoreco Pune)',
        cpcbRegNumber: 'CPCB-REG-EWASTE-2024-MH-0842',
        facilityLat: 18.5204,
        facilityLon: 73.8567,
        distanceKm: 4.2,
        facilityAddress: 'Plot 42, Bhosari MIDC, Pune - 411026',
        acceptedClasses: 'pcb_telecom,pcb_motherboard,lithium_ion,copper_cables',
        logisticsCapability: 'DOORSTEP_PICKUP',
        verificationStatus: 'ACTIVE_VERIFIED',
        rating: 4.9,
        totalHandovers: 1420,
        priceMultiplier: 1.05,
        contactPerson: 'Milind Patil (Procurement Officer)',
        contactPhone: '+91 98230 45678',
        minLotWeightKg: 10.0,
      );

      const recycler2 = RecyclerData(
        recyclerId: 'REC_GREENIVA_02',
        legalEntityName: 'Greeniva E-Waste Processors Pvt Ltd',
        cpcbRegNumber: 'CPCB-REG-EWASTE-2023-MH-1109',
        facilityLat: 18.6298,
        facilityLon: 73.7997,
        distanceKm: 12.8,
        facilityAddress: 'Gat No 124, Chakan Industrial Area, Phase II',
        acceptedClasses: 'crt_monitors,lead_acid,mixed_plastics',
        logisticsCapability: 'FACILITY_DROP_ONLY',
        verificationStatus: 'ACTIVE_VERIFIED',
        rating: 4.7,
        totalHandovers: 890,
        priceMultiplier: 1.00,
        contactPerson: 'Suresh Deshmukh',
        contactPhone: '+91 98221 11223',
        minLotWeightKg: 25.0,
      );

      db.insertRecycler(recycler1);
      db.insertRecycler(recycler2);

      final recyclers = db.getAllRecyclers();
      expect(recyclers.length, greaterThanOrEqualTo(5));

      // Verify matching logic: recycler 1 accepts 'pcb_telecom', recycler 2 does not
      final matchedForPcb = recyclers.where((r) => r.acceptedClasses.contains('pcb_telecom')).toList();
      expect(matchedForPcb.any((r) => r.recyclerId == 'REC_ECORECO_01'), isTrue);
    });

    test('3. Lot Creation with AI Density Verification against Water/Sand Fraud', () {
      // Case A: Authentic 43 kg motherboard lot
      final legitLot = DensityFraudDetector.analyse(
        bbox: [40, 60, 400, 480],
        frameW: 480,
        frameH: 640,
        weightKg: 43.0,
        subCategory: 'motherboard',
      );
      expect(legitLot.severity, isNot(equals(FraudSeverity.flag)));

      // Case B: Water/wet sand soaked battery box (500 kg for a tiny 20x20 pixel bounding box)
      final fraudLot = DensityFraudDetector.analyse(
        bbox: [100, 100, 120, 120],
        frameW: 480,
        frameH: 640,
        weightKg: 500.0,
        subCategory: 'motherboard',
      );
      expect(fraudLot.severity, equals(FraudSeverity.flag));
      expect(fraudLot.message, isNotNull);
    });

    test('4. Lot registration, Cryptographic Token Generation, and Verification', () {
      const lotId = 'LOT-2026-RAMESH-001';
      const collectorId = 'COL-PUNE-RAMESH-9822';
      const estWeightKg = 15.0;
      const ratePerKg = 510.0;

      // Register lot in SQLite
      final lot = MaterialsData(
        lotId: lotId,
        collectorId: collectorId,
        category: 'pcb_telecom',
        subCategory: 'Telecom Servers',
        conditionGrade: 'A',
        estWeightKg: estWeightKg,
        estValuationInr: estWeightKg * ratePerKg, // Rs. 7,650
        imageEdgeHash: 'HASH_EDGE_SAMPLE_001',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      db.insertMaterial(lot);

      // Recycler and Collector generate signed HMAC QR payload
      final payloadJson = QrSigner.buildPayload(
        txId: 'TX-2026-RAMESH-001',
        lotId: lotId,
        collectorId: collectorId,
        lat: 18.5204,
        lon: 73.8567,
        category: 'pcb_telecom',
        subCategory: 'Telecom Servers',
        estWeightKg: estWeightKg,
        quotedValueInr: estWeightKg * ratePerKg,
        netOfferedPriceInr: ratePerKg,
      );

      final signedBlob = QrSigner.sign(payloadJson);

      // Verify QR envelope decryption and validity
      final verificationResult = QrSigner.verify(signedBlob);
      expect(verificationResult.valid, isTrue);
      expect(verificationResult.payload!['lot_id'], lotId);
      expect(verificationResult.payload!['price']['net_offered_price_inr'], ratePerKg);
      expect(verificationResult.payload!['material']['est_weight_kg'], estWeightKg);
    });

    test('5. Certified Scale Handover Confirmation, Spot Cash settlement, and Outbox Sync', () async {
      const txId = 'TXN-ECORECO-RAMESH-8841';
      const lotId = 'LOT-2026-RAMESH-001';
      const recyclerId = 'REC_ECORECO_01';

      // Certified scale weight at weighbridge: 14.8 kg (slightly lower than 15.0 kg estimate)
      const certifiedScaleWeightKg = 14.8;
      const finalRatePerKg = 510.0;
      const finalGrossAmount = certifiedScaleWeightKg * finalRatePerKg; // Rs. 7,548.00

      // Recycler settles via Spot Cash
      final transaction = TransactionsData(
        txId: txId,
        lotId: lotId,
        quotedValueInr: 7650.0,
        finalSettledInr: finalGrossAmount,
        settlementMode: 'CASH',
        txLifecycleState: 'SETTLED',
        recyclerId: recyclerId,
        recyclerName: 'Eco Recycling Ltd (Ecoreco Pune)',
        category: 'pcb_telecom',
        weightKg: certifiedScaleWeightKg,
        quoteTimestamp: DateTime.now().millisecondsSinceEpoch - 3600000,
        settlementTs: DateTime.now().millisecondsSinceEpoch,
        paymentReference: 'CASH-RECEIPT-8841',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      db.upsertTransaction(transaction);

      // Traceability record created for CPCB Form-6 Manifest
      final trace = TraceabilityData(
        traceId: 'TRACE-CPCB-2026-MH-7712',
        lotId: lotId,
        txId: txId,
        handoverQrHash: 'HMAC_SHA256_VERIFIED_7712',
        edgeTimestamp: DateTime.now().millisecondsSinceEpoch,
        handoverLat: 18.5204,
        handoverLon: 73.8567,
        verificationStatus: 'CERTIFIED_VERIFIED',
        recyclerSignature: 'REC_SIG_MILIND_PATIL',
        collectorSignature: 'COL_SIG_RAMESH_SHINDE',
        cpcbBatchId: 'CPCB-MH-BATCH-0089',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      db.insertTraceability(trace);

      // Verify transaction retrieval from SQLite ledger
      final allTxns = db.getAllTransactions();
      expect(allTxns.length, greaterThanOrEqualTo(3));
      final savedTxn = allTxns.firstWhere((t) => t.txId == txId);
      expect(savedTxn.txId, txId);
      expect(savedTxn.txLifecycleState, 'SETTLED');
      expect(savedTxn.settlementMode, 'CASH');
      expect(savedTxn.finalSettledInr, 7548.0);

      // Offline outbox queue for server synchronization when connectivity is restored
      final outboxItem = OutboxData(
        id: 'OUTBOX-TXN-8841',
        entityType: 'TRANSACTION',
        entityId: txId,
        payloadJson: jsonEncode(savedTxn.toMap()),
        status: 'PENDING',
        retryCount: 0,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      db.addOutbox(outboxItem);

      var pending = db.getPendingOutbox();
      expect(pending.length, 1);
      expect(pending.first.status, 'PENDING');

      // Simulate network sync completion
      db.markOutboxSynced([pending.first.id]);
      pending = db.getPendingOutbox();
      expect(pending.isEmpty, isTrue);
    });
  });
}
