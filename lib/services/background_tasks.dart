import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../core/constants/app_constants.dart';
import 'bookmark_service.dart';
import 'firebase_config.dart';
import 'notification_service.dart';

/// Periodic background check for new advertisements and closing-soon
/// reminders. Runs in a background isolate via Workmanager — no Blaze
/// plan and no server code required.
///
/// The task is registered from [schedulePeriodicCheck] (called once at
/// app startup). Android enforces a minimum 15-minute interval; we use
/// one hour to stay battery-friendly.
@pragma('vm:entry-point')
void backgroundTaskDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != AppConstants.bgCheckTaskName) return true;
    try {
      await FirebaseConfig.initialize();
      final bookmarks = BookmarkService();
      await bookmarks.load();
      final notifications = NotificationService();
      await notifications.checkForUpdates(bookmarks: bookmarks);
      return true;
    } catch (e) {
      debugPrint('Background check failed: $e');
      // Return true so Workmanager keeps the periodic schedule alive.
      return true;
    }
  });
}

/// Registers the periodic background check. Safe to call on every
/// startup: [ExistingPeriodicWorkPolicy.keep] preserves the existing
/// schedule instead of replacing it.
Future<void> schedulePeriodicCheck() async {
  try {
    await Workmanager().initialize(backgroundTaskDispatcher);
    await Workmanager().registerPeriodicTask(
      AppConstants.bgCheckTaskName,
      AppConstants.bgCheckTaskName,
      frequency: const Duration(hours: 1),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  } catch (e) {
    debugPrint('Failed to schedule background check: $e');
  }
}

/// Cancels the periodic background check (used when the user disables
/// all notification types).
Future<void> cancelPeriodicCheck() async {
  try {
    await Workmanager().cancelByUniqueName(AppConstants.bgCheckTaskName);
  } catch (e) {
    debugPrint('Failed to cancel background check: $e');
  }
}
