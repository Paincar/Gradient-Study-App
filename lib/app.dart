import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/rose_pine_theme.dart';
import 'providers.dart';
import 'ui/common/floating_bottom_nav.dart';
import 'ui/focus/focus_screen.dart';
import 'ui/home/home_screen.dart';
import 'ui/notes/notes_screen.dart';
import 'ui/onboarding/onboarding_screen.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/tests/test_hub_screen.dart';
import 'ui/timetable/timetable_screen.dart';

import 'data/datasources/local_store.dart';

import 'ui/splash/splash_screen.dart';

class GradientApp extends ConsumerStatefulWidget {
  const GradientApp({super.key});

  @override
  ConsumerState<GradientApp> createState() => _GradientAppState();
}

class _GradientAppState extends ConsumerState<GradientApp> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileNotifierProvider);

    return MaterialApp(
      title: 'Gradient',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(paletteKey: profile.accentPalette),
      darkTheme: AppTheme.darkTheme(paletteKey: profile.accentPalette),
      themeMode: profile.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _showSplash
          ? SplashScreen(
              onFinish: () {
                setState(() => _showSplash = false);
              },
            )
          : const MainNavigationHost(),
    );
  }
}

/// Backward compatible alias
typedef FocusPathApp = GradientApp;

class MainNavigationHost extends ConsumerStatefulWidget {
  const MainNavigationHost({super.key});

  @override
  ConsumerState<MainNavigationHost> createState() => _MainNavigationHostState();
}

class _MainNavigationHostState extends ConsumerState<MainNavigationHost> {
  int _currentIndex = 0;
  late bool _isOnboarded;

  @override
  void initState() {
    super.initState();
    _isOnboarded = ref.read(localStoreProvider).hasCompletedOnboarding;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOnboarded) {
      return OnboardingScreen(
        onFinish: () async {
          await ref.read(localStoreProvider).setOnboardingCompleted(true);
          setState(() {
            _isOnboarded = true;
          });
        },
      );
    }

    final screens = [
      HomeScreen(onNavigateTab: (idx) => setState(() => _currentIndex = idx)),
      const TimetableScreen(),
      const FocusScreen(),
      const TestHubScreen(),
      const NotesScreen(),
      const SettingsScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar: FloatingBottomNav(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
        ),
      ),
    );
  }
}
