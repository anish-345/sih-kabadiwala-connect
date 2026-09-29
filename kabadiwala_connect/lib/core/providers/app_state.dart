import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfile {
  final String id;
  final String name;
  final String phone;
  final String role; // 'collector' or 'recycler'
  final String region;
  final String language; // 'hi', 'mr', 'en'

  final double lat;
  final double lon;

  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.region = 'Pune (MH-PUN)',
    this.language = 'hi',
    this.lat = 18.5204,
    this.lon = 73.8567,
  });

  String get displayName {
    if (role == 'recycler') {
      return switch (language) {
        'en' => 'Vikram Deshmukh (MIDC Bhosari)',
        'mr' => 'विक्रम देशमुख (एमआयडीसी भोसरी)',
        _ => 'विक्रम देशमुख (एमआईडीसी भोसरी)',
      };
    }
    return switch (language) {
      'en' => 'Ramesh Shinde',
      'mr' => 'रमेश शिंदे',
      _ => 'रमेश शिंदे',
    };
  }

  String get localizedRegion => switch (language) {
        'en' => 'Nana Peth, Pune',
        'mr' => 'नाना पेठ, पुणे',
        _ => 'नाना पेठ, पुणे',
      };

  UserProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? role,
    String? region,
    String? language,
    double? lat,
    double? lon,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      region: region ?? this.region,
      language: language ?? this.language,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
    );
  }
}

class AppStateNotifier extends StateNotifier<UserProfile> {
  AppStateNotifier()
      : super(const UserProfile(
          id: 'COLL-PUN-0042',
          name: 'रमेश शिंदे (Ramesh Shinde)',
          phone: '+91 98221 44021',
          role: 'collector',
          region: 'नाना पेठ (Nana Peth, Pune)',
          language: 'hi',
        ));

  void setLanguage(String lang) {
    state = state.copyWith(language: lang);
  }

  void setRole(String role) {
    if (role == 'recycler') {
      state = state.copyWith(
        id: 'REC-DESK-01',
        name: 'विक्रम देशमुख (E-Incarnation MIDC Bhosari)',
        phone: '+91 98220 14890',
        role: 'recycler',
      );
    } else {
      state = state.copyWith(
        id: 'COLL-PUN-0042',
        name: 'रमेश शिंदे (Ramesh Shinde)',
        phone: '+91 98221 44021',
        role: 'collector',
      );
    }
  }

  void setPhone(String phone) {
    state = state.copyWith(phone: phone);
  }
}

final appStateProvider = StateNotifierProvider<AppStateNotifier, UserProfile>((ref) {
  return AppStateNotifier();
});
