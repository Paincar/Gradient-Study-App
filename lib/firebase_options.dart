import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for Gradient.
/// 
/// If you place your `google-services.json` in `android/app/`,
/// Android will automatically link to your custom Firebase project.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDemoKey-GradientSPPU2026WebKey',
    appId: '1:100000000000:web:gradientwebdemo123',
    messagingSenderId: '100000000000',
    projectId: 'gradient-sppu',
    authDomain: 'gradient-sppu.firebaseapp.com',
    storageBucket: 'gradient-sppu.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDemoKey-GradientSPPU2026AndroidKey',
    appId: '1:100000000000:android:gradientandroid123',
    messagingSenderId: '100000000000',
    projectId: 'gradient-sppu',
    storageBucket: 'gradient-sppu.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDemoKey-GradientSPPU2026IosKey',
    appId: '1:100000000000:ios:gradientiosdemo123',
    messagingSenderId: '100000000000',
    projectId: 'gradient-sppu',
    storageBucket: 'gradient-sppu.appspot.com',
    iosBundleId: 'com.focuspath.app',
  );
}
