import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not supported');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBSL_JQt8mgeKv98dD1CRjbnPovexh89eU',
    appId: '1:879833296604:android:1251bf9035dbd47ed94e19',
    messagingSenderId: '879833296604',
    projectId: 'marcagol2026',
    storageBucket: 'marcagol2026.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyADk7ENs1cgmjRWZL_rKbdTJ2c2ksr6SYU',
    appId: '1:879833296604:ios:177f10eee861e9c6d94e19',
    messagingSenderId: '879833296604',
    projectId: 'marcagol2026',
    storageBucket: 'marcagol2026.firebasestorage.app',
    iosBundleId: 'com.marcagol.marcaGol',
  );

}