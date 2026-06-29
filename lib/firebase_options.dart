import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web desteklenmiyor');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Desteklenmeyen platform: $defaultTargetPlatform');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDHEbwnepk_AaBXauUaJFZuTqAKjCm2MV8',
    appId: '1:313942210216:android:c8a15820486a122617f49d',
    messagingSenderId: '313942210216',
    projectId: 'pehlivan-isg',
    storageBucket: 'pehlivan-isg.firebasestorage.app',
  );
}
