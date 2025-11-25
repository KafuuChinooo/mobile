import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration extracted from android/app/google-services.json.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCOt9BMkVSrqAa9bOjRiE625rZhU8D0pgE',
    appId: '1:829105870894:android:61e121ac34873a401667bf',
    messagingSenderId: '829105870894',
    projectId: 'flashcard-c5996',
    storageBucket: 'flashcard-c5996.firebasestorage.app',
  );
}
