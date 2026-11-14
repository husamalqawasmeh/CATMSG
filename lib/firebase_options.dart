// File generated template for FlutterFire CLI.
// Run `flutterfire configure` in the project root to replace this file with
// your live Firebase project credentials.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  /// Returns true when real Firebase credentials have been configured.
  /// When false, CatMsg runs in instant Local/Demo Mode with full interactive
  /// features so you can test the app immediately before running `flutterfire configure`.
  static bool get isFirebaseConfigured {
    try {
      final options = currentPlatform;
      return !options.apiKey.startsWith('REPLACE_WITH_');
    } catch (_) {
      return false;
    }
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_WEB_API_KEY',
    appId: '1:000000000000:web:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'catmsg-discord-app',
    authDomain: 'catmsg-discord-app.firebaseapp.com',
    storageBucket: 'catmsg-discord-app.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_ANDROID_API_KEY',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'catmsg-discord-app',
    storageBucket: 'catmsg-discord-app.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_IOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'catmsg-discord-app',
    storageBucket: 'catmsg-discord-app.appspot.com',
    iosBundleId: 'com.catmsg.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_MACOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'catmsg-discord-app',
    storageBucket: 'catmsg-discord-app.appspot.com',
    iosBundleId: 'com.catmsg.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_WINDOWS_API_KEY',
    appId: '1:000000000000:web:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'catmsg-discord-app',
    authDomain: 'catmsg-discord-app.firebaseapp.com',
    storageBucket: 'catmsg-discord-app.appspot.com',
  );
}
