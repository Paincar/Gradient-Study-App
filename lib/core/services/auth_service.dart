import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../firebase_options.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  static const String appDebugSha1 = 'F6:84:D5:F0:83:70:18:6A:4F:12:82:AF:DF:95:70:D5:1B:59:38:A7';
  static const String appDebugSha256 = 'F7:D6:60:7F:0D:E5:32:79:60:8C:E9:56:22:C7:9E:E1:C7:E0:8A:ED:E7:B7:E7:09:A8:F7:35:4A:05:A5:18:9F';
  static const String appPackageName = 'com.focuspath.app';

  bool _isFirebaseReady = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  final StreamController<User?> _authStreamController =
      StreamController<User?>.broadcast();

  // Local fallback student profile
  String? _localDisplayName;
  String? _localEmail;

  bool get isFirebaseReady => _isFirebaseReady;
  bool get hasLocalProfile => _localDisplayName != null && _localDisplayName!.isNotEmpty;
  String get effectiveDisplayName => currentUser?.displayName ?? _localDisplayName ?? 'Student';
  String get effectiveEmail => currentUser?.email ?? _localEmail ?? 'student@sppu.edu';

  void setLocalProfile(String name, String email) {
    _localDisplayName = name;
    _localEmail = email;
  }

  void clearLocalProfile() {
    _localDisplayName = null;
    _localEmail = null;
  }

  Stream<User?> get authStateChanges {
    if (_isFirebaseReady) {
      return FirebaseAuth.instance.authStateChanges();
    }
    return _authStreamController.stream;
  }

  User? get currentUser {
    if (_isFirebaseReady) {
      return FirebaseAuth.instance.currentUser;
    }
    return null;
  }

  Future<void> init() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isFirebaseReady = true;
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (!_authStreamController.isClosed) {
          _authStreamController.add(user);
        }
      });
    } catch (e) {
      debugPrint('Firebase initialization notice (running in offline-resilient mode): $e');
      _isFirebaseReady = false;
    }
  }

  /// Sign in using Google OAuth Credentials
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        if (!_isFirebaseReady) await init();
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          // User canceled Google Sign-In
          return null;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        if (!_isFirebaseReady) await init();
        if (_isFirebaseReady) {
          return await FirebaseAuth.instance.signInWithCredential(credential);
        }
        return null;
      }
    } catch (e) {
      debugPrint('Google Sign-In exception: $e');
      final errorStr = e.toString();
      if (errorStr.contains('10') || errorStr.contains('sign_in_fail')) {
        throw const GoogleSignInConfigException(
          'Google Sign-In requires your Firebase project to have package "com.focuspath.app" registered with SHA-1 fingerprint and google-services.json in android/app/.',
          sha1: appDebugSha1,
        );
      }
      rethrow;
    }
  }

  /// Sign out from Google and Firebase
  Future<void> signOut() async {
    try {
      clearLocalProfile();
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      if (_isFirebaseReady) {
        await FirebaseAuth.instance.signOut();
      }
      if (!_authStreamController.isClosed) {
        _authStreamController.add(null);
      }
    } catch (e) {
      debugPrint('Sign-out error: $e');
    }
  }
}

class GoogleSignInConfigException implements Exception {
  final String message;
  final String sha1;
  const GoogleSignInConfigException(this.message, {this.sha1 = AuthService.appDebugSha1});
  @override
  String toString() => message;
}
