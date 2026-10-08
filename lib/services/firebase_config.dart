import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration for the Afzal Opportunities app.
///
/// This file is a hand-written placeholder. Run `flutterfire configure`
/// (see docs/setup.md) to regenerate it with your real project values —
/// never paste real API keys or service-account JSON into the source tree.
///
/// Until real values are configured, [isConfigured] stays false and the app
/// runs in demo mode with bundled sample advertisements.
class FirebaseConfig {
  const FirebaseConfig._();

  /// Whether real Firebase credentials have been configured.
  static const bool isConfigured = false;

  /// Placeholder options — never real credentials.
  static const FirebaseOptions options = FirebaseOptions(
    apiKey: '__NOT_CONFIGURED__',
    appId: '__NOT_CONFIGURED__',
    messagingSenderId: '__NOT_CONFIGURED__',
    projectId: '__NOT_CONFIGURED__',
    storageBucket: '__NOT_CONFIGURED__',
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
