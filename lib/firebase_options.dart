// File generated manually for Hybrid mode.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCzaL1X4DXUp2jHVF7q7P8CcDilFiojrZ4',
    appId: '1:180155275159:web:6ba988ba9f5817258116d2',
    messagingSenderId: '180155275159',
    projectId: 'spark-lingo',
    authDomain: 'spark-lingo.firebaseapp.com',
    storageBucket: 'spark-lingo.firebasestorage.app',
    measurementId: 'G-V8DHDR68S3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCzaL1X4DXUp2jHVF7q7P8CcDilFiojrZ4',
    appId: '1:180155275159:android:6ba988ba9f5817258116d2',
    messagingSenderId: '180155275159',
    projectId: 'spark-lingo',
    storageBucket: 'spark-lingo.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCzaL1X4DXUp2jHVF7q7P8CcDilFiojrZ4',
    appId: '1:180155275159:ios:6ba988ba9f5817258116d2',
    messagingSenderId: '180155275159',
    projectId: 'spark-lingo',
    storageBucket: 'spark-lingo.firebasestorage.app',
    iosBundleId: 'com.sparklingo.sparkLingo',
  );
}
