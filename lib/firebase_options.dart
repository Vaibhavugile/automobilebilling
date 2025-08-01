// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDTFKQp5GNMfhjmXFXKS2riKYMseqorNYU',
    appId: '1:951307594838:web:264bb5e7df0ce503335ff7',
    messagingSenderId: '951307594838',
    projectId: 'jamale-56944',
    authDomain: 'jamale-56944.firebaseapp.com',
    storageBucket: 'jamale-56944.firebasestorage.app',
    measurementId: 'G-7Y0YR6ZH86',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAJnwHyg5kkyL5cmzh5tHnXv3Pz-Hoqz-g',
    appId: '1:951307594838:android:9755ddc41c4c2f97335ff7',
    messagingSenderId: '951307594838',
    projectId: 'jamale-56944',
    storageBucket: 'jamale-56944.firebasestorage.app',
  );
}
