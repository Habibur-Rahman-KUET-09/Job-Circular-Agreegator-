// Hand-written (not `flutterfire configure`-generated) from the
// google-services.json downloaded from the Firebase console — this
// sandbox can't run `flutterfire configure` itself (it needs an
// interactive `firebase login`). Android-only, matching this app's
// android-only platform support (see pubspec.yaml's flutter_launcher_icons
// `ios: false` note). Re-run `flutterfire configure` for a real generated
// version if iOS/web support is ever added.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web — this '
        'app is Android-only.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for '
          '$defaultTargetPlatform — this app is Android-only.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDhGl1CZGQKwkk1ySYX5YaE-beSDw7pZ4M',
    appId: '1:164954399351:android:0f6ad632198eb3c8f15c72',
    messagingSenderId: '164954399351',
    projectId: 'shondhan-58fe0',
    storageBucket: 'shondhan-58fe0.firebasestorage.app',
  );
}
