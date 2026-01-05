import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 각 화면 직접 import
import 'package:frontend/features/splash/presentation/screens/splash_screen.dart';
import 'package:frontend/features/menu/presentation/screens/menu_screen.dart';
import 'package:frontend/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:frontend/features/settings/presentation/screens/settings_screen.dart';
import 'package:frontend/features/history/presentation/screens/history_screen.dart';
import 'package:frontend/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:frontend/features/profile/presentation/screens/relationship_screen.dart';
import 'package:frontend/features/saju_chat/presentation/screens/saju_chat_shell.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapScreen(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(useMaterial3: true),
        home: child,
      ),
    );
  }

  group('Screenshot All Pages', () {
    testWidgets('01_splash', (tester) async {
      await tester.pumpWidget(wrapScreen(const SplashScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      await binding.takeScreenshot('01_splash');
    });

    testWidgets('02_onboarding', (tester) async {
      await tester.pumpWidget(wrapScreen(const OnboardingScreen()));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('02_onboarding');
    });

    testWidgets('03_menu', (tester) async {
      await tester.pumpWidget(wrapScreen(const MenuScreen()));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('03_menu');
    });

    testWidgets('04_settings', (tester) async {
      await tester.pumpWidget(wrapScreen(const SettingsScreen()));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('04_settings');
    });

    testWidgets('05_history', (tester) async {
      await tester.pumpWidget(wrapScreen(const HistoryScreen()));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('05_history');
    });

    testWidgets('06_profile_edit', (tester) async {
      await tester.pumpWidget(wrapScreen(const ProfileEditScreen()));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('06_profile_edit');
    });

    testWidgets('07_relationships', (tester) async {
      await tester.pumpWidget(wrapScreen(const RelationshipScreen()));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('07_relationships');
    });

    testWidgets('08_saju_chat', (tester) async {
      await tester.pumpWidget(wrapScreen(const SajuChatShell()));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('08_saju_chat');
    });
  });
}
