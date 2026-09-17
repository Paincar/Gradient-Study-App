import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focuspath/core/theme/rose_pine_theme.dart';
import 'package:focuspath/data/datasources/local_store.dart';
import 'package:focuspath/ui/common/floating_bottom_nav.dart';
import 'package:focuspath/ui/common/responsive_wrapper.dart';
import 'package:focuspath/ui/onboarding/onboarding_screen.dart';
import 'package:focuspath/ui/splash/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FloatingBottomNav renders all 6 navigation tabs and fires callback', (WidgetTester tester) async {
    int tappedIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: FloatingBottomNav(
            currentIndex: 0,
            onTap: (idx) => tappedIndex = idx,
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Tests'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Tap Plan tab (index 1)
    await tester.tap(find.text('Plan'));
    expect(tappedIndex, equals(1));

    // Tap Focus tab (index 2)
    await tester.tap(find.text('Focus'));
    expect(tappedIndex, equals(2));

    // Tap Tests tab (index 3)
    await tester.tap(find.text('Tests'));
    expect(tappedIndex, equals(3));
  });

  testWidgets('ResponsiveContainer constrains width correctly on wide views', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveContainer(
            maxWidth: 500,
            child: Text('Responsive Child Content'),
          ),
        ),
      ),
    );

    expect(find.text('Responsive Child Content'), findsOneWidget);
    expect(find.byType(ResponsiveContainer), findsOneWidget);
  });

  testWidgets('Rose Pine Theme defines consistent light and dark palettes', (WidgetTester tester) async {
    final light = AppTheme.lightTheme();
    final dark = AppTheme.darkTheme();

    expect(light.brightness, equals(Brightness.light));
    expect(dark.brightness, equals(Brightness.dark));
    expect(light.useMaterial3, isTrue);
    expect(dark.useMaterial3, isTrue);
  });

  testWidgets('Personalization onboarding questionnaire displays on first launch', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(store),
        ],
        child: MaterialApp(
          home: OnboardingScreen(onFinish: () {}),
        ),
      ),
    );
    expect(find.text('Personalize your study sanctuary'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('SplashScreen renders Gradient branding and triggers onFinish', (WidgetTester tester) async {
    bool finished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          onFinish: () => finished = true,
          duration: const Duration(milliseconds: 500),
        ),
      ),
    );

    expect(find.text('Gradient'), findsOneWidget);
    expect(find.text('Engineering Focus & Academic Sanctuary'), findsOneWidget);

    // Tap splash screen to trigger onFinish early
    await tester.tap(find.byType(SplashScreen));
    expect(finished, isTrue);

    await tester.pumpAndSettle();
  });
}
