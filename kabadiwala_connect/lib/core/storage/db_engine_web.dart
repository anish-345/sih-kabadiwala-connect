import 'db_engine.dart';

class WebDbEngine implements DbEngine {
  final Map<String, List<Map<String, dynamic>>> _tables = {
    'price_feed': [],
    'recyclers': [],
    'materials': [],
    'transactions': [],
    'traceability': [],
    'outbox': [],
  };

  @override
  void execute(String sql, [List<Object?> parameters = const []]) {
    final lower = sql.trim().toLowerCase();

    if (lower.startsWith('create table')) {
      final match = RegExp(r'create\s+table\s+(?:if\s+not\s+exists\s+)?([a-zA-Z0-9_]+)', caseSensitive: false).firstMatch(sql);
      if (match != null) {
        final table = match.group(1)!.toLowerCase();
        _tables.putIfAbsent(table, () => []);
      }
      return;
    }

    if (lower.startsWith('insert or replace into price_feed') || lower.startsWith('insert into price_feed')) {
      if (parameters.length >= 13) {
        final row = {
          'price_record_id': parameters[0],
          'category': parameters[1],
          'sub_category': parameters[2],
          'geo_region_code': parameters[3],
          'informal_base_rate': parameters[4],
          'formal_gate_rate': parameters[5],
          'epr_credit_share': parameters[6],
          'ncmm_incentive': parameters[7],
          'net_offered_price': parameters[8],
          'trend': parameters[9],
          'trend_delta_percent': parameters[10],
          'trend_history_json': parameters[11],
          'hazard_type': parameters[12],
          'source': parameters.length > 13 ? parameters[13] : '',
          'notes': parameters.length > 16 ? parameters[16] : '',
        };
        _tables['price_feed']!.removeWhere((r) => r['price_record_id'] == row['price_record_id']);
        _tables['price_feed']!.add(row);
      }
      return;
    }

    if (lower.startsWith('insert or replace into recyclers') || lower.startsWith('insert into recyclers')) {
      if (parameters.length >= 14) {
        final row = {
          'recycler_id': parameters[0],
          'legal_entity_name': parameters[1],
          'cpcb_reg_number': parameters[2],
          'facility_lat': parameters[3],
          'facility_lon': parameters[4],
          'distance_km': parameters[5],
          'facility_address': parameters[6],
          'accepted_classes': parameters[7],
          'logistics_capability': parameters[8],
          'verification_status': parameters[9],
          'valid_until': parameters[10],
          'rating': parameters[11],
          'total_handovers': parameters[12],
          'price_multiplier': parameters[13],
        };
        _tables['recyclers']!.removeWhere((r) => r['recycler_id'] == row['recycler_id']);
        _tables['recyclers']!.add(row);
      }
      return;
    }

    if (lower.startsWith('insert into materials')) {
      if (parameters.length >= 14) {
        final row = {
          'lot_id': parameters[0],
          'collector_id': parameters[1],
          'category': parameters[2],
          'sub_category': parameters[3],
          'condition_grade': parameters[4],
          'est_weight_kg': parameters[5],
          'est_valuation_inr': parameters[6],
          'image_edge_hash': parameters[7],
          'photo_path': parameters[8],
          'is_fraud_flagged': parameters[9],
          'fraud_reason': parameters[10],
          'lat': parameters[11],
          'lon': parameters[12],
          'created_at': parameters[13],
        };
        _tables['materials']!.add(row);
      }
      return;
    }

    if (lower.startsWith('insert into transactions')) {
      if (parameters.length >= 13) {
        final row = {
          'tx_id': parameters[0],
          'lot_id': parameters[1],
          'quoted_value_inr': parameters[2],
          'final_settled_inr': parameters[3],
          'settlement_mode': parameters[4],
          'tx_lifecycle_state': parameters[5],
          'recycler_id': parameters[6],
          'recycler_name': parameters[7],
          'category': parameters[8],
          'weight_kg': parameters[9],
          'quote_timestamp': parameters[10],
          'settlement_ts': parameters[11],
          'payment_reference': parameters[12],
          'created_at': parameters.length > 13 ? parameters[13] : DateTime.now().millisecondsSinceEpoch,
        };
        _tables['transactions']!.add(row);
      }
      return;
    }

    if (lower.startsWith('insert into outbox')) {
      if (parameters.length >= 6) {
        final row = {
          'id': parameters[0],
          'entity_type': parameters[1],
          'entity_id': parameters[2],
          'payload_json': parameters[3],
          'status': parameters[4],
          'retry_count': 0,
          'created_at': parameters[5],
          'last_attempt': null,
        };
        _tables['outbox']!.add(row);
      }
      return;
    }

    if (lower.startsWith('update outbox set status')) {
      for (final r in _tables['outbox']!) {
        r['status'] = 'SYNCED';
      }
      return;
    }
  }

  @override
  List<Map<String, dynamic>> select(String sql, [List<Object?> parameters = const []]) {
    final lower = sql.trim().toLowerCase();

    if (lower.contains('count(*) as c from price_feed')) {
      return [{'c': _tables['price_feed']!.length}];
    }

    if (lower.contains('count(*) as c from recyclers')) {
      return [{'c': _tables['recyclers']!.length}];
    }

    if (lower.contains('count(*) as c from outbox')) {
      final pendingCount = _tables['outbox']!.where((r) => r['status'] == 'PENDING').length;
      return [{'c': pendingCount}];
    }

    if (lower.contains('from price_feed')) {
      final list = List<Map<String, dynamic>>.from(_tables['price_feed']!);
      if (parameters.isNotEmpty && lower.contains('category =')) {
        return list.where((r) => r['category'] == parameters[0]).toList();
      }
      if (parameters.isNotEmpty && lower.contains('price_record_id =')) {
        return list.where((r) => r['price_record_id'] == parameters[0]).toList();
      }
      return list;
    }

    if (lower.contains('from recyclers')) {
      final list = List<Map<String, dynamic>>.from(_tables['recyclers']!);
      if (parameters.isNotEmpty && lower.contains('recycler_id =')) {
        return list.where((r) => r['recycler_id'] == parameters[0]).toList();
      }
      return list;
    }

    if (lower.contains('from materials')) {
      return List<Map<String, dynamic>>.from(_tables['materials']!);
    }

    if (lower.contains('from transactions')) {
      return List<Map<String, dynamic>>.from(_tables['transactions']!);
    }

    if (lower.contains('from outbox')) {
      return _tables['outbox']!.where((r) => r['status'] == 'PENDING').toList();
    }

    return [];
  }

  @override
  void close() {}
}

Future<DbEngine> openPlatformDb({bool inMemory = false}) async {
  return WebDbEngine();
}
