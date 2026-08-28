// File generated based on Firebase project hodcams-cf37a
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAEZJTa1SuijApKSZ6KAkVnJHRPATRBIZw',
    appId: '1:220720657288:web:dd1989e3384ed5933dc03d',
    messagingSenderId: '220720657288',
    projectId: 'hodcams-cf37a',
    authDomain: 'hodcams-cf37a.firebaseapp.com',
    storageBucket: 'hodcams-cf37a.firebasestorage.app',
    measurementId: 'G-3HC7BQZD3H',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAEZJTa1SuijApKSZ6KAkVnJHRPATRBIZw',
    appId: '1:220720657288:web:dd1989e3384ed5933dc03d',
    messagingSenderId: '220720657288',
    projectId: 'hodcams-cf37a',
    storageBucket: 'hodcams-cf37a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAEZJTa1SuijApKSZ6KAkVnJHRPATRBIZw',
    appId: '1:220720657288:web:dd1989e3384ed5933dc03d',
    messagingSenderId: '220720657288',
    projectId: 'hodcams-cf37a',
    storageBucket: 'hodcams-cf37a.firebasestorage.app',
    iosClientId: '',
    iosBundleId: 'com.example.hodFlutter',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAEZJTa1SuijApKSZ6KAkVnJHRPATRBIZw',
    appId: '1:220720657288:web:dd1989e3384ed5933dc03d',
    messagingSenderId: '220720657288',
    projectId: 'hodcams-cf37a',
    storageBucket: 'hodcams-cf37a.firebasestorage.app',
    iosClientId: '',
    iosBundleId: 'com.example.hodFlutter',
  );
}
