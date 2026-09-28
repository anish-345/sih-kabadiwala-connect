import 'dart:convert';

class PriceFeedData {
  final String priceRecordId;
  final String category;
  final String subCategory;
  final String geoRegionCode;
  final double informalBaseRate;
  final double formalGateRate;
  final double eprCreditShare;
  final double ncmmIncentive;
  final double netOfferedPrice;
  final String trend;
  final double trendDeltaPercent;
  final List<double> trendHistory;
  final String hazardType;
  final String source;
  final int effectiveFrom;
  final int effectiveTo;
  final String notes;

  const PriceFeedData({
    required this.priceRecordId,
    required this.category,
    required this.subCategory,
    required this.geoRegionCode,
    required this.informalBaseRate,
    required this.formalGateRate,
    required this.eprCreditShare,
    required this.ncmmIncentive,
    required this.netOfferedPrice,
    required this.trend,
    this.trendDeltaPercent = 0.0,
    this.trendHistory = const [],
    this.hazardType = 'NONE',
    required this.source,
    required this.effectiveFrom,
    required this.effectiveTo,
    this.notes = '',
  });

  factory PriceFeedData.fromJson(Map<String, dynamic> json) {
    return PriceFeedData(
      priceRecordId: json['priceRecordId'] as String? ?? '',
      category: json['category'] as String? ?? 'Mixed',
      subCategory: json['subCategory'] as String? ?? '',
      geoRegionCode: json['geoRegionCode'] as String? ?? 'MH-PUN',
      informalBaseRate: (json['informalBaseRate'] as num?)?.toDouble() ?? 0.0,
      formalGateRate: (json['formalGateRate'] as num?)?.toDouble() ?? 0.0,
      eprCreditShare: (json['eprCreditShare'] as num?)?.toDouble() ?? 0.0,
      ncmmIncentive: (json['ncmmIncentive'] as num?)?.toDouble() ?? 0.0,
      netOfferedPrice: (json['netOfferedPrice'] as num?)?.toDouble() ?? 0.0,
      trend: json['trend'] as String? ?? 'STABLE',
      trendDeltaPercent: (json['trendDeltaPercent'] as num?)?.toDouble() ?? 0.0,
      trendHistory: (json['trendHistory'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [],
      hazardType: json['hazardType'] as String? ?? 'NONE',
      source: json['source'] as String? ?? '',
      effectiveFrom: json['effectiveFrom'] as int? ?? 0,
      effectiveTo: json['effectiveTo'] as int? ?? 0,
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'price_record_id': priceRecordId,
      'category': category,
      'sub_category': subCategory,
      'geo_region_code': geoRegionCode,
      'informal_base_rate': informalBaseRate,
      'formal_gate_rate': formalGateRate,
      'epr_credit_share': eprCreditShare,
      'ncmm_incentive': ncmmIncentive,
      'net_offered_price': netOfferedPrice,
      'trend': trend,
      'trend_delta_percent': trendDeltaPercent,
      'trend_history_json': jsonEncode(trendHistory),
      'hazard_type': hazardType,
      'source': source,
      'effective_from': effectiveFrom,
      'effective_to': effectiveTo,
      'notes': notes,
    };
  }

  factory PriceFeedData.fromRow(Map<String, dynamic> row) {
    List<double> history = [];
    try {
      final jsonStr = row['trend_history_json'] as String?;
      if (jsonStr != null && jsonStr.isNotEmpty) {
        history = (jsonDecode(jsonStr) as List<dynamic>)
            .map((e) => (e as num).toDouble())
            .toList();
      }
    } catch (_) {}

    return PriceFeedData(
      priceRecordId: row['price_record_id'] as String,
      category: row['category'] as String? ?? 'PCB',
      subCategory: row['sub_category'] as String,
      geoRegionCode: row['geo_region_code'] as String,
      informalBaseRate: (row['informal_base_rate'] as num).toDouble(),
      formalGateRate: (row['formal_gate_rate'] as num).toDouble(),
      eprCreditShare: (row['epr_credit_share'] as num).toDouble(),
      ncmmIncentive: (row['ncmm_incentive'] as num).toDouble(),
      netOfferedPrice: (row['net_offered_price'] as num).toDouble(),
      trend: row['trend'] as String? ?? 'STABLE',
      trendDeltaPercent: (row['trend_delta_percent'] as num?)?.toDouble() ?? 0.0,
      trendHistory: history,
      hazardType: row['hazard_type'] as String? ?? 'NONE',
      source: row['source'] as String? ?? '',
      effectiveFrom: row['effective_from'] as int? ?? 0,
      effectiveTo: row['effective_to'] as int? ?? 0,
      notes: row['notes'] as String? ?? '',
    );
  }
}

class RecyclerData {
  final String recyclerId;
  final String legalEntityName;
  final String cpcbRegNumber;
  final double facilityLat;
  final double facilityLon;
  final double distanceKm;
  final String facilityAddress;
  final String acceptedClasses;
  final String logisticsCapability;
  final String verificationStatus;
  final String validUntil;
  final double rating;
  final int totalHandovers;
  final double priceMultiplier;
  final String contactPerson;
  final String contactPhone;
  final double minLotWeightKg;
  final List<String> features;

  const RecyclerData({
    required this.recyclerId,
    required this.legalEntityName,
    required this.cpcbRegNumber,
    required this.facilityLat,
    required this.facilityLon,
    this.distanceKm = 5.0,
    required this.facilityAddress,
    required this.acceptedClasses,
    required this.logisticsCapability,
    required this.verificationStatus,
    this.validUntil = '2027-12-31',
    this.rating = 4.8,
    this.totalHandovers = 0,
    this.priceMultiplier = 1.0,
    this.contactPerson = '',
    this.contactPhone = '',
    this.minLotWeightKg = 5.0,
    this.features = const [],
  });

  factory RecyclerData.fromJson(Map<String, dynamic> json) {
    return RecyclerData(
      recyclerId: json['recyclerId'] as String? ?? '',
      legalEntityName: json['legalEntityName'] as String? ?? '',
      cpcbRegNumber: json['cpcbRegNumber'] as String? ?? '',
      facilityLat: (json['facilityLat'] as num?)?.toDouble() ?? 18.5204,
      facilityLon: (json['facilityLon'] as num?)?.toDouble() ?? 73.8567,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 5.0,
      facilityAddress: json['facilityAddress'] as String? ?? '',
      acceptedClasses: json['acceptedClasses'] as String? ?? '',
      logisticsCapability: json['logisticsCapability'] as String? ?? 'SELF_DROP',
      verificationStatus: json['verificationStatus'] as String? ?? 'CPCB_CERTIFIED',
      validUntil: json['validUntil'] as String? ?? '2027-12-31',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      totalHandovers: json['totalHandovers'] as int? ?? 0,
      priceMultiplier: (json['priceMultiplier'] as num?)?.toDouble() ?? 1.0,
      contactPerson: json['contactPerson'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      minLotWeightKg: (json['minLotWeightKg'] as num?)?.toDouble() ?? 5.0,
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recycler_id': recyclerId,
      'legal_entity_name': legalEntityName,
      'cpcb_reg_number': cpcbRegNumber,
      'facility_lat': facilityLat,
      'facility_lon': facilityLon,
      'distance_km': distanceKm,
      'facility_address': facilityAddress,
      'accepted_classes': acceptedClasses,
      'logistics_capability': logisticsCapability,
      'verification_status': verificationStatus,
      'valid_until': validUntil,
      'rating': rating,
      'total_handovers': totalHandovers,
      'price_multiplier': priceMultiplier,
      'contact_person': contactPerson,
      'contact_phone': contactPhone,
      'min_lot_weight_kg': minLotWeightKg,
      'features_json': jsonEncode(features),
    };
  }

  factory RecyclerData.fromRow(Map<String, dynamic> row) {
    List<String> feats = [];
    try {
      final jsonStr = row['features_json'] as String?;
      if (jsonStr != null && jsonStr.isNotEmpty) {
        feats = (jsonDecode(jsonStr) as List<dynamic>).map((e) => e.toString()).toList();
      }
    } catch (_) {}

    return RecyclerData(
      recyclerId: row['recycler_id'] as String,
      legalEntityName: row['legal_entity_name'] as String,
      cpcbRegNumber: row['cpcb_reg_number'] as String,
      facilityLat: (row['facility_lat'] as num).toDouble(),
      facilityLon: (row['facility_lon'] as num).toDouble(),
      distanceKm: (row['distance_km'] as num?)?.toDouble() ?? 5.0,
      facilityAddress: row['facility_address'] as String,
      acceptedClasses: row['accepted_classes'] as String,
      logisticsCapability: row['logistics_capability'] as String,
      verificationStatus: row['verification_status'] as String,
      validUntil: row['valid_until'] as String? ?? '2027-12-31',
      rating: (row['rating'] as num?)?.toDouble() ?? 4.8,
      totalHandovers: row['total_handovers'] as int? ?? 0,
      priceMultiplier: (row['price_multiplier'] as num?)?.toDouble() ?? 1.0,
      contactPerson: row['contact_person'] as String? ?? '',
      contactPhone: row['contact_phone'] as String? ?? '',
      minLotWeightKg: (row['min_lot_weight_kg'] as num?)?.toDouble() ?? 5.0,
      features: feats,
    );
  }
}

class MaterialsData {
  final String lotId;
  final String collectorId;
  final String category;
  final String subCategory;
  final String conditionGrade;
  final double estWeightKg;
  final double estValuationInr;
  final String imageEdgeHash;
  final String? photoPath;
  final bool isFraudFlagged;
  final String? fraudReason;
  final double? lat;
  final double? lon;
  final int createdAt;

  const MaterialsData({
    required this.lotId,
    required this.collectorId,
    required this.category,
    required this.subCategory,
    required this.conditionGrade,
    required this.estWeightKg,
    required this.estValuationInr,
    required this.imageEdgeHash,
    this.photoPath,
    this.isFraudFlagged = false,
    this.fraudReason,
    this.lat,
    this.lon,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'lot_id': lotId,
      'collector_id': collectorId,
      'category': category,
      'sub_category': subCategory,
      'condition_grade': conditionGrade,
      'est_weight_kg': estWeightKg,
      'est_valuation_inr': estValuationInr,
      'image_edge_hash': imageEdgeHash,
      'photo_path': photoPath,
      'is_fraud_flagged': isFraudFlagged ? 1 : 0,
      'fraud_reason': fraudReason,
      'lat': lat,
      'lon': lon,
      'created_at': createdAt,
    };
  }

  factory MaterialsData.fromRow(Map<String, dynamic> row) {
    return MaterialsData(
      lotId: row['lot_id'] as String,
      collectorId: row['collector_id'] as String,
      category: row['category'] as String,
      subCategory: row['sub_category'] as String,
      conditionGrade: row['condition_grade'] as String,
      estWeightKg: (row['est_weight_kg'] as num).toDouble(),
      estValuationInr: (row['est_valuation_inr'] as num).toDouble(),
      imageEdgeHash: row['image_edge_hash'] as String,
      photoPath: row['photo_path'] as String?,
      isFraudFlagged: (row['is_fraud_flagged'] as int? ?? 0) == 1,
      fraudReason: row['fraud_reason'] as String?,
      lat: (row['lat'] as num?)?.toDouble(),
      lon: (row['lon'] as num?)?.toDouble(),
      createdAt: row['created_at'] as int,
    );
  }
}

class TransactionsData {
  final String txId;
  final String lotId;
  final double quotedValueInr;
  final double finalSettledInr;
  final String settlementMode; // 'CASH', 'UPI'
  final String txLifecycleState; // 'QUOTED', 'MATCHED', 'SETTLED', 'SYNCED'
  final String? recyclerId;
  final String? recyclerName;
  final String? category;
  final double weightKg;
  final int quoteTimestamp;
  final int? settlementTs;
  final String? paymentReference;
  final int createdAt;

  const TransactionsData({
    required this.txId,
    required this.lotId,
    required this.quotedValueInr,
    required this.finalSettledInr,
    required this.settlementMode,
    required this.txLifecycleState,
    this.recyclerId,
    this.recyclerName,
    this.category,
    this.weightKg = 0.0,
    required this.quoteTimestamp,
    this.settlementTs,
    this.paymentReference,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'tx_id': txId,
      'lot_id': lotId,
      'quoted_value_inr': quotedValueInr,
      'final_settled_inr': finalSettledInr,
      'settlement_mode': settlementMode,
      'tx_lifecycle_state': txLifecycleState,
      'recycler_id': recyclerId,
      'recycler_name': recyclerName,
      'category': category,
      'weight_kg': weightKg,
      'quote_timestamp': quoteTimestamp,
      'settlement_ts': settlementTs,
      'payment_reference': paymentReference,
      'created_at': createdAt,
    };
  }

  factory TransactionsData.fromRow(Map<String, dynamic> row) {
    return TransactionsData(
      txId: row['tx_id'] as String,
      lotId: row['lot_id'] as String,
      quotedValueInr: (row['quoted_value_inr'] as num).toDouble(),
      finalSettledInr: (row['final_settled_inr'] as num).toDouble(),
      settlementMode: row['settlement_mode'] as String,
      txLifecycleState: row['tx_lifecycle_state'] as String,
      recyclerId: row['recycler_id'] as String?,
      recyclerName: row['recycler_name'] as String?,
      category: row['category'] as String?,
      weightKg: (row['weight_kg'] as num?)?.toDouble() ?? 0.0,
      quoteTimestamp: row['quote_timestamp'] as int,
      settlementTs: row['settlement_ts'] as int?,
      paymentReference: row['payment_reference'] as String?,
      createdAt: row['created_at'] as int,
    );
  }
}

class TraceabilityData {
  final String traceId;
  final String lotId;
  final String txId;
  final String handoverQrHash;
  final int edgeTimestamp;
  final double handoverLat;
  final double handoverLon;
  final String handoverPhotoUri;
  final String verificationStatus; // 'PENDING', 'VERIFIED_OFFLINE', 'SYNCED_PORTAL'
  final String recyclerSignature;
  final String collectorSignature;
  final String cpcbBatchId;
  final int createdAt;

  const TraceabilityData({
    required this.traceId,
    required this.lotId,
    required this.txId,
    required this.handoverQrHash,
    required this.edgeTimestamp,
    required this.handoverLat,
    required this.handoverLon,
    this.handoverPhotoUri = '',
    required this.verificationStatus,
    this.recyclerSignature = '',
    this.collectorSignature = '',
    this.cpcbBatchId = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'trace_id': traceId,
      'lot_id': lotId,
      'tx_id': txId,
      'handover_qr_hash': handoverQrHash,
      'edge_timestamp': edgeTimestamp,
      'handover_lat': handoverLat,
      'handover_lon': handoverLon,
      'handover_photo_uri': handoverPhotoUri,
      'verification_status': verificationStatus,
      'recycler_signature': recyclerSignature,
      'collector_signature': collectorSignature,
      'cpcb_batch_id': cpcbBatchId,
      'created_at': createdAt,
    };
  }

  factory TraceabilityData.fromRow(Map<String, dynamic> row) {
    return TraceabilityData(
      traceId: row['trace_id'] as String,
      lotId: row['lot_id'] as String,
      txId: row['tx_id'] as String? ?? '',
      handoverQrHash: row['handover_qr_hash'] as String,
      edgeTimestamp: row['edge_timestamp'] as int,
      handoverLat: (row['handover_lat'] as num).toDouble(),
      handoverLon: (row['handover_lon'] as num).toDouble(),
      handoverPhotoUri: row['handover_photo_uri'] as String? ?? '',
      verificationStatus: row['verification_status'] as String,
      recyclerSignature: row['recycler_signature'] as String? ?? '',
      collectorSignature: row['collector_signature'] as String? ?? '',
      cpcbBatchId: row['cpcb_batch_id'] as String? ?? '',
      createdAt: row['created_at'] as int,
    );
  }
}

class OutboxData {
  final String id;
  final String entityType;
  final String entityId;
  final String payloadJson;
  final String status; // 'PENDING', 'SYNCED', 'FAILED'
  final int retryCount;
  final int createdAt;
  final int? lastAttempt;

  const OutboxData({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.payloadJson,
    this.status = 'PENDING',
    this.retryCount = 0,
    required this.createdAt,
    this.lastAttempt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'payload_json': payloadJson,
      'status': status,
      'retry_count': retryCount,
      'created_at': createdAt,
      'last_attempt': lastAttempt,
    };
  }

  factory OutboxData.fromRow(Map<String, dynamic> row) {
    return OutboxData(
      id: row['id'] as String,
      entityType: row['entity_type'] as String,
      entityId: row['entity_id'] as String,
      payloadJson: row['payload_json'] as String,
      status: row['status'] as String,
      retryCount: row['retry_count'] as int? ?? 0,
      createdAt: row['created_at'] as int,
      lastAttempt: row['last_attempt'] as int?,
    );
  }
}
