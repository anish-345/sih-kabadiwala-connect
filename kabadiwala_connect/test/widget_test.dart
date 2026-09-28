import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabadiwala_connect/app.dart';
import 'package:kabadiwala_connect/core/storage/database.dart';

void main() {
  testWidgets('KabadiwalaApp launches to LanguageScreen without errors', (WidgetTester tester) async {
    // Set standard phone screen dimensions
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    final db = await AppDatabase.create(inMemory: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const KabadiwalaApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Language options
    expect(find.text('कबाड़ीवाला कनेक्ट'), findsOneWidget);
    expect(find.text('हिन्दी'), findsOneWidget);
    expect(find.text('मराठी'), findsOneWidget);
    expect(find.text('English'), findsAtLeastNWidgets(1));

    // Clean up
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      db.close();
    });
  });
}
