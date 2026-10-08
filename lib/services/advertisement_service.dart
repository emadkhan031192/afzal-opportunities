import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/deadline.dart';
import '../models/advertisement.dart';
import 'demo_ads.dart';
import 'firebase_config.dart';

/// How advertisements should be ordered in the feed.
enum AdSortMode {
  /// Featured first, then NEW, then nearest deadline.
  relevance,

  /// Nearest deadline first; advertisements without a deadline last.
  nearestDeadline,
}

/// Reads advertisements from Firestore, or from bundled demo data when
/// Firebase is not configured.
///
/// Invalid documents are skipped (and logged) so one corrupt record can
/// never break the feed.
class AdvertisementService {
  AdvertisementService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Live stream of published advertisements, newest first.
  Stream<List<Advertisement>> watchPublished() {
    if (!FirebaseConfig.isConfigured) {
      return Stream<List<Advertisement>>.value(DemoAds.ads);
    }
    return _db
        .collection(AppConstants.advertisementsCollection)
        .where('status', isEqualTo: AppConstants.statusPublished)
        .snapshots()
        .map(_parseSnapshot);
  }

  /// One-shot fetch of published advertisements, newest first.
  Future<List<Advertisement>> fetchPublished() async {
    if (!FirebaseConfig.isConfigured) {
      return DemoAds.ads;
    }
    final snapshot = await _db
        .collection(AppConstants.advertisementsCollection)
        .where('status', isEqualTo: AppConstants.statusPublished)
        .get();
    return _parseSnapshot(snapshot);
  }

  /// Fetches a single advertisement by id, or null when missing/invalid.
  Future<Advertisement?> getById(String id) async {
    if (!FirebaseConfig.isConfigured) {
      return DemoAds.byId(id);
    }
    final doc = await _db
        .collection(AppConstants.advertisementsCollection)
        .doc(id)
        .get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      return null;
    }
    try {
      return Advertisement.fromJson(doc.id, data);
    } on FormatException catch (error) {
      debugPrint('Skipping invalid advertisement ${doc.id}: $error');
      return null;
    }
  }

  List<Advertisement> _parseSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final ads = <Advertisement>[];
    for (final doc in snapshot.docs) {
      try {
        ads.add(Advertisement.fromJson(doc.id, doc.data()));
      } on FormatException catch (error) {
        debugPrint('Skipping invalid advertisement ${doc.id}: $error');
      }
    }
    // Sorted client-side so no composite Firestore index is required.
    ads.sort(_comparePublishedDesc);
    return ads;
  }

  static int _comparePublishedDesc(Advertisement a, Advertisement b) {
    final pa = a.publishedAt;
    final pb = b.publishedAt;
    if (pa == null && pb == null) {
      return 0;
    }
    if (pa == null) {
      return 1;
    }
    if (pb == null) {
      return -1;
    }
    return pb.compareTo(pa);
  }
}

/// Keeps only advertisements that are active right now
/// (published and not past their last date, evaluated in PKT).
List<Advertisement> filterActiveAds(List<Advertisement> ads, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  return ads.where((ad) => ad.isActiveAt(clock)).toList();
}

/// Keeps advertisements of [category], or all when [category] is 'all'.
List<Advertisement> filterByCategory(List<Advertisement> ads, String category) {
  if (category == AppConstants.allCategoriesId) {
    return List<Advertisement>.of(ads);
  }
  return ads.where((ad) => ad.category == category).toList();
}

/// Orders [ads] by [mode] without mutating the input list.
List<Advertisement> sortAds(
  List<Advertisement> ads,
  AdSortMode mode, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final sorted = List<Advertisement>.of(ads);
  switch (mode) {
    case AdSortMode.nearestDeadline:
      sorted.sort(
        (a, b) => _deadlineRank(a, clock).compareTo(_deadlineRank(b, clock)),
      );
    case AdSortMode.relevance:
      sorted.sort((a, b) {
        if (a.isFeatured != b.isFeatured) {
          return a.isFeatured ? -1 : 1;
        }
        final aNew = _isNewAd(a, clock);
        final bNew = _isNewAd(b, clock);
        if (aNew != bNew) {
          return aNew ? -1 : 1;
        }
        return _deadlineRank(a, clock).compareTo(_deadlineRank(b, clock));
      });
  }
  return sorted;
}

/// Sort key: days left until the deadline; advertisements without a
/// deadline (or expired ones) sort last.
int _deadlineRank(Advertisement ad, DateTime now) {
  final info = getDeadlineInfo(
    lastDate: ad.lastDate,
    publishedAt: ad.publishedAt,
    now: now,
  );
  final daysLeft = info.daysLeft;
  if (daysLeft == null || daysLeft < 0) {
    return 1 << 30;
  }
  return daysLeft;
}

bool _isNewAd(Advertisement ad, DateTime now) {
  return getDeadlineInfo(
    lastDate: ad.lastDate,
    publishedAt: ad.publishedAt,
    now: now,
  ).isNew;
}
