import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/deadline.dart';
import '../models/advertisement.dart';
import 'advertisement_service.dart';
import 'bookmark_service.dart';
import 'firebase_config.dart';

/// Notification categories. Each has its own opt-in preference;
/// promotions are off by default and everything else is on by default.
enum NotificationType { newAds, closingSoon, teaching, promotions }

/// Local-notification system for Afzal E Services.
///
/// Works without Blaze / server code: a periodic background task
/// (see `background_tasks.dart`) calls [checkForUpdates], which re-runs
/// the app's published-only Firestore query, compares against a stored
/// watermark, and fires local notifications for genuinely new items.
/// Every notification is de-duplicated so a restart or re-check can
/// never notify twice for the same item.
class NotificationService {
  NotificationService({SharedPreferences? prefs}) : _prefs = prefs;

  final SharedPreferences? _prefs;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static String _prefKey(NotificationType type) {
    switch (type) {
      case NotificationType.newAds:
        return AppConstants.notifNewAdsKey;
      case NotificationType.closingSoon:
        return AppConstants.notifClosingSoonKey;
      case NotificationType.teaching:
        return AppConstants.notifTeachingKey;
      case NotificationType.promotions:
        return AppConstants.notifPromotionsKey;
    }
  }

  /// Default opt-in state per type. Promotions are always opt-in.
  static bool defaultEnabled(NotificationType type) {
    return type != NotificationType.promotions;
  }

  Future<SharedPreferences> get _store async =>
      _prefs ?? SharedPreferences.getInstance();

  /// Creates the notification channel and asks for permission on
  /// Android 13+. Safe to call more than once.
  Future<void> initialize() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);
    const channel = AndroidNotificationChannel(
      AppConstants.notifChannelId,
      'Afzal E Services',
      description: 'New opportunities and deadline reminders',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    _initialized = true;
  }

  /// Requests the runtime notification permission (Android 13+).
  /// Returns true when notifications are (or remain) allowed.
  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    return await android.requestNotificationsPermission() ?? false;
  }

  Future<bool> isEnabled(NotificationType type) async {
    final prefs = await _store;
    return prefs.getBool(_prefKey(type)) ?? defaultEnabled(type);
  }

  Future<void> setEnabled(NotificationType type, bool enabled) async {
    final prefs = await _store;
    await prefs.setBool(_prefKey(type), enabled);
  }

  /// One background-check pass: new published ads + closing-soon
  /// reminders for saved ads. Updates the watermark afterwards.
  Future<void> checkForUpdates({
    AdvertisementService? adService,
    BookmarkService? bookmarks,
  }) async {
    if (!FirebaseConfig.isConfigured) return;
    await initialize();
    final prefs = await _store;

    final now = DateTime.now().toUtc();
    final lastCheckRaw = prefs.getString(AppConstants.notifLastCheckKey);
    final lastCheck = lastCheckRaw == null
        ? null
        : DateTime.tryParse(lastCheckRaw);
    final isFirstRun = lastCheck == null;

    final service = adService ?? AdvertisementService();
    List<Advertisement> ads;
    try {
      ads = await service.fetchPublished();
    } catch (e) {
      debugPrint('Notification check: failed to fetch ads: $e');
      return;
    }

    final seenIds = prefs.getStringList(AppConstants.notifSeenIdsKey) ?? [];

    // New published advertisements since the last check.
    if (await isEnabled(NotificationType.newAds) && !isFirstRun) {
      for (final ad in ads) {
        final publishedAt = ad.publishedAt ?? ad.createdAt;
        if (publishedAt == null) continue;
        if (!publishedAt.toUtc().isAfter(lastCheck!)) continue;
        if (seenIds.contains(_seenKey(ad.id))) continue;
        await _show(
          id: ad.id.hashCode,
          title: 'New: ${ad.title}',
          body:
              '${ad.organization} · ${AppConstants.categoryLabel(ad.category)}',
        );
        seenIds.add(_seenKey(ad.id));
      }
    }

    // Closing-soon reminders for saved advertisements (1-2 days left),
    // de-duplicated per advertisement per day.
    if (await isEnabled(NotificationType.closingSoon) && bookmarks != null) {
      final today = _dayKey(now);
      for (final id in bookmarks.ids) {
        Advertisement? ad;
        try {
          ad = await service.getById(id);
        } catch (e) {
          debugPrint('Notification check: failed to fetch ad $id: $e');
          continue;
        }
        if (ad == null) continue;
        final info = getDeadlineInfo(
          lastDate: ad.lastDate,
          publishedAt: ad.publishedAt,
        );
        final days = info.daysLeft;
        if (days == null || days < 1 || days > 2 || info.isExpired) continue;
        final key = 'closing:$id:$today';
        if (seenIds.contains(key)) continue;
        await _show(
          id: key.hashCode,
          title: 'Closing soon: ${ad.title}',
          body: days == 1
              ? 'Last date is tomorrow · ${ad.organization}'
              : '$days days left · ${ad.organization}',
        );
        seenIds.add(key);
      }
    }

    // Cap the dedup list so it cannot grow without bound.
    final trimmed = seenIds.length > 300
        ? seenIds.sublist(seenIds.length - 300)
        : seenIds;
    await prefs.setStringList(AppConstants.notifSeenIdsKey, trimmed);
    await prefs.setString(
      AppConstants.notifLastCheckKey,
      now.toIso8601String(),
    );
  }

  /// Fires a teaching-vacancy notification (called by the teaching
  /// module's own background check; kept here so channel/prefs stay
  /// in one place).
  Future<void> notifyTeaching({
    required String id,
    required String title,
    required String body,
  }) async {
    if (!await isEnabled(NotificationType.teaching)) return;
    await initialize();
    final prefs = await _store;
    final seenIds = prefs.getStringList(AppConstants.notifSeenIdsKey) ?? [];
    final key = _seenKey('teaching:$id');
    if (seenIds.contains(key)) return;
    await _show(id: key.hashCode, title: title, body: body);
    seenIds.add(key);
    final trimmed = seenIds.length > 300
        ? seenIds.sublist(seenIds.length - 300)
        : seenIds;
    await prefs.setStringList(AppConstants.notifSeenIdsKey, trimmed);
  }

  static String _seenKey(String id) => 'seen:$id';

  static String _dayKey(DateTime utc) =>
      '${utc.year}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')}';

  Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notifChannelId,
        'Afzal E Services',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    try {
      await _plugin.show(id, title, body, details);
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }
}
