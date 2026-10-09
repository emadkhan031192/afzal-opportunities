import 'package:flutter/material.dart';

import 'app.dart';
import 'core/l10n/locale_controller.dart';
import 'core/theme/theme_controller.dart';
import 'services/background_tasks.dart';
import 'services/bookmark_service.dart';
import 'services/firebase_config.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initializes only when real credentials are configured
  // (see lib/services/firebase_config.dart). Otherwise the app runs in
  // demo mode with bundled sample advertisements.
  await FirebaseConfig.initialize();

  final themeController = ThemeController();
  await themeController.load();

  final localeController = LocaleController();
  await localeController.load();

  final bookmarkService = BookmarkService();
  await bookmarkService.load();

  // Local notifications: channel setup + runtime permission (Android 13+).
  // The periodic background check runs even without permission; it just
  // cannot display anything until the user grants it.
  final notifications = NotificationService();
  await notifications.requestPermission();
  await schedulePeriodicCheck();

  runApp(
    AfzalApp(
      themeController: themeController,
      localeController: localeController,
      bookmarkService: bookmarkService,
      notificationService: notifications,
    ),
  );
}
