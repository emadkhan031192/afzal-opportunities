import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration for the Afzal Opportunities app.
///
/// These are public Firebase *client* identifiers (project "afzal-opportunities",
/// created 2026-10-08). They are meant to be embedded in apps and are safe to
/// commit — real access control lives in firestore.rules / storage.rules.
/// Never commit service-account JSON or private keys.
class FirebaseConfig {
  const FirebaseConfig._();

  /// Whether real Firebase credentials have been configured.
  static const bool isConfigured = true;

  /// Firebase options for project "afzal-opportunities".
  static const FirebaseOptions options = FirebaseOptions(
    apiKey: 'AIzaSyBJ2CaZHdCkHr9C815VQTJU3bRvi-OLJz4',
    appId: '1:727260702840:android:53d5dd93ff7eab2dca658d',
    messagingSenderId: '727260702840',
    projectId: 'afzal-opportunities',
    storageBucket: 'afzal-opportunities.firebasestorage.app',
  );

  /// Initializes Firebase only when configured; otherwise logs and returns
  /// so the app can run in demo mode.
  static Future<void> initialize() async {
    if (!isConfigured) {
      debugPrint(
        'Firebase is not configured — '
        'Afzal Opportunities is running in demo mode.',
      );
      return;
    }
    await Firebase.initializeApp(options: options);
  }
}
