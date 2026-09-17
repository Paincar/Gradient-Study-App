import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../firebase_options.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  bool _isFirebaseReady = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  final StreamController<User?> _authStreamController =
      StreamController<User?>.broadcast();

  bool get isFirebaseReady => _isFirebaseReady;

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
      rethrow;
    }
  }

  /// Sign out from Google and Firebase
  Future<void> signOut() async {
    try {
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
