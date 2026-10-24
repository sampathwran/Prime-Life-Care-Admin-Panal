import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for Prime Life Care Admin panel.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.macOS:
        return web;
      case TargetPlatform.iOS:
        return web;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAdDvfVMwFaJIhWVy0lGjAUty0kwb8B6gg',
    appId: '1:790518603401:web:3e4585ca277d2315777058',
    messagingSenderId: '790518603401',
    projectId: 'prime-life-care-dcacf',
    authDomain: 'prime-life-care-dcacf.firebaseapp.com',
    storageBucket: 'prime-life-care-dcacf.firebasestorage.app',
    measurementId: 'G-4GLH5SKFF5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA9ouFkIsOx2yrWryOzaL5jJqYcb4GP76Y',
    appId: '1:790518603401:android:b8c16eb837b87437777058',
    messagingSenderId: '790518603401',
    projectId: 'prime-life-care-dcacf',
    storageBucket: 'prime-life-care-dcacf.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAdDvfVMwFaJIhWVy0lGjAUty0kwb8B6gg',
    appId: '1:790518603401:web:3e4585ca277d2315777058',
    messagingSenderId: '790518603401',
    projectId: 'prime-life-care-dcacf',
    authDomain: 'prime-life-care-dcacf.firebaseapp.com',
    storageBucket: 'prime-life-care-dcacf.firebasestorage.app',
    measurementId: 'G-4GLH5SKFF5',
  );
}
