import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/auth_service.dart';
import 'data/datasources/local_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Protect against unhandled widget errors causing black screens
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Gradient FlutterError: ${details.exception}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF191724),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Something went wrong while rendering:\n${details.exception}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFE0DEF4), fontSize: 14),
          ),
        ),
      ),
    );
  };

  // Initialize offline local store safely
  final localStore = LocalStore();
  try {
    await localStore.init();
  } catch (e, stack) {
    debugPrint('Gradient LocalStore init error: $e\n$stack');
  }

  // Initialize Firebase AuthService safely
  try {
    await AuthService.instance.init();
  } catch (e) {
    debugPrint('Gradient AuthService init notice: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(localStore),
      ],
      child: const GradientApp(),
    ),
  );
}
