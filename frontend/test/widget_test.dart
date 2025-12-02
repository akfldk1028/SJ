// Mantok app basic widget test
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/app.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MantokApp(),
      ),
    );

    // App should launch without errors
    expect(find.byType(MantokApp), findsOneWidget);
  });
}
