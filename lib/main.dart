import 'package:flutter/material.dart';

import 'app.dart';
import 'core/theme/theme_controller.dart';
import 'services/bookmark_service.dart';
import 'services/firebase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initializes only when real credentials are configured
  // (see lib/services/firebase_config.dart). Otherwise the app runs in
  // demo mode with bundled sample advertisements.
  await FirebaseConfig.initialize();

  final themeController = ThemeController();
  await themeController.load();

  final bookmarkService = BookmarkService();
  await bookmarkService.load();

  runApp(
    AfzalApp(
      themeController: themeController,
      bookmarkService: bookmarkService,
    ),
  );
}
