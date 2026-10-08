import '../../models/advertisement.dart';
import '../../services/advertisement_service.dart';

/// Sort options offered in the feed UI.
///
/// `latest` (newest published first) is a UI-level mode; [relevance] and
/// [nearestDeadline] delegate to [AdSortMode] in the service layer, which
/// must not be modified by the UI.
enum FeedSortMode { latest, relevance, nearestDeadline }

/// Display label for a [FeedSortMode].
extension FeedSortModeLabel on FeedSortMode {
  String get label {
    switch (this) {
      case FeedSortMode.latest:
        return 'Latest';
      case FeedSortMode.relevance:
        return 'Relevance';
      case FeedSortMode.nearestDeadline:
        return 'Deadline';
    }
  }
}

/// Orders [ads] by [mode] without mutating the input list.
List<Advertisement> sortFeedAds(
  List<Advertisement> ads,
  FeedSortMode mode, {
  DateTime? now,
}) {
  if (mode == FeedSortMode.latest) {
    final sorted = List<Advertisement>.of(ads);
    sorted.sort((a, b) {
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
    });
    return sorted;
  }
  return sortAds(
    ads,
    mode == FeedSortMode.relevance
        ? AdSortMode.relevance
        : AdSortMode.nearestDeadline,
    now: now,
  );
}
