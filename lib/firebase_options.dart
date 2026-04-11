import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
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
    apiKey: 'AIzaSyCv0tGpAK3I0J7-P9C9Gb8mehTgD0T27HI',
    appId: '1:1037343578785:web:8538ea64b5e3b6c67f6ee0',
    messagingSenderId: '1037343578785',
    projectId: 'hadaya-4d357',
    authDomain: 'hadaya-4d357.firebaseapp.com',
    storageBucket: 'hadaya-4d357.firebasestorage.app',
    measurementId: 'G-0FS2WCY45W',
  );

  // TODO: replace with real Firebase config after running: flutterfire configure

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBZsxEt-E0JSlzTVsHIGqgMkyN64cSEmyg',
    appId: '1:1037343578785:android:d2893817b4b18d967f6ee0',
    messagingSenderId: '1037343578785',
    projectId: 'hadaya-4d357',
    storageBucket: 'hadaya-4d357.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBngZLEtPMR-__LXcUW4zVu4Z0GMPwSzu4',
    appId: '1:1037343578785:ios:537d128132e61bf47f6ee0',
    messagingSenderId: '1037343578785',
    projectId: 'hadaya-4d357',
    storageBucket: 'hadaya-4d357.firebasestorage.app',
    iosClientId: '1037343578785-l8e6ie2lduc06ocrq7g5leg7rd42pn4b.apps.googleusercontent.com',
    iosBundleId: 'com.hadiya.hadiya',
  );

}