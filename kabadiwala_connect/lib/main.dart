import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/app_state.dart';
import 'core/storage/database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait on phones
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Open the real SQLite database (seeds prices & recyclers if first run)
  final db = await AppDatabase.create();

  // Initialize shared preferences for persistent language & user settings
  final prefs = await SharedPreferences.getInstance();

  // Register observer to properly close database and stream controllers on app exit
  WidgetsBinding.instance.addObserver(_AppLifecycleObserver(db));

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const KabadiwalaApp(),
    ),
  );
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  final AppDatabase db;

  _AppLifecycleObserver(this.db);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      db.close();
    }
  }
}
