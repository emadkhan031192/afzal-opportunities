import 'package:afzal_opportunities/models/advertisement.dart';
import 'package:afzal_opportunities/services/advertisement_service.dart';
import 'package:flutter_test/flutter_test.dart';

Advertisement ad({
  required String id,
  String status = 'published',
  DateTime? lastDate,
  String category = 'jobs',
  bool featured = false,
  DateTime? publishedAt,
}) {
  return Advertisement(
    id: id,
    title: 'Title $id',
    organization: 'Org',
    category: category,
    description: 'Description',
    status: status,
    lastDate: lastDate,
    isFeatured: featured,
    publishedAt: publishedAt,
  );
}

void main() {
  // 12:00 UTC == 17:00 PKT on 2026-10-08.
  final now = DateTime.utc(2026, 10, 8, 12);

  group('filterActiveAds', () {
    test('hides expired, draft and archived; keeps no-deadline published',
        () {
      final ads = [
        ad(id: 'active', lastDate: DateTime(2026, 10, 20)),
        ad(id: 'no-deadline'),
        ad(id: 'expired', lastDate: DateTime(2026, 10, 1)),
        ad(id: 'draft', status: 'draft', lastDate: DateTime(2026, 10, 20)),
          ad(id: 'archived', status: 'archived', lastDate: DateTime(2026, 10, 20)),
      ];
      final result = filterActiveAds(ads, now: now);
      final ids = result.map((a) => a.id).toList();
      expect(ids, containsAll(['active', 'no-deadline']));
      expect(ids, isNot(contains('expired')));
      expect(ids, isNot(contains('draft')));
      expect(ids, isNot(contains('archived')));
    });

    test('keeps an ad active on its last date', () {
      final ads = [ad(id: 'today', lastDate: DateTime(2026, 10, 8))];
      expect(
        filterActiveAds(ads, now: now).map((a) => a.id),
        contains('today'),
      );
    });
  });

  group('filterByCategory', () {
    test('filters to the requested category', () {
      final ads = [
        ad(id: 'a', category: 'jobs'),
        ad(id: 'b', category: 'scholarships'),
        ad(id: 'c', category: 'jobs'),
      ];
      final result = filterByCategory(ads, 'jobs');
      expect(result.map((a) => a.id), ['a', 'c']);
    });

    test('"all" returns every advertisement', () {
      final ads = [
        ad(id: 'a', category: 'jobs'),
        ad(id: 'b', category: 'other'),
      ];
      expect(filterByCategory(ads, 'all').length, 2);
    });

    test('unknown category returns an empty list', () {
      final ads = [ad(id: 'a', category: 'jobs')];
      expect(filterByCategory(ads, 'lottery'), isEmpty);
    });
  });

  group('sortAds', () {
    test('nearestDeadline orders by days left, deadline-less last', () {
      final ads = [
        ad(id: 'far', lastDate: DateTime(2026, 10, 18)),
        ad(id: 'none'),
        ad(id: 'near', lastDate: DateTime(2026, 10, 11)),
        ad(id: 'mid', lastDate: DateTime(2026, 10, 15)),
      ];
      final result = sortAds(ads, AdSortMode.nearestDeadline, now: now);
      expect(result.map((a) => a.id), ['near', 'mid', 'far', 'none']);
    });

    test(
      'relevance puts featured first, then NEW, then nearest deadline',
      () {
      final ads = [
        ad(
          id: 'plain-near',
          lastDate: DateTime(2026, 10, 11),
          publishedAt: now.subtract(const Duration(days: 10)),
        ),
        ad(
          id: 'featured',
          featured: true,
          lastDate: DateTime(2026, 11, 8),
          publishedAt: now.subtract(const Duration(days: 10)),
        ),
        ad(
          id: 'fresh',
          lastDate: DateTime(2026, 11, 8),
          publishedAt: now.subtract(const Duration(hours: 5)),
        ),
        ad(
          id: 'plain-far',
          lastDate: DateTime(2026, 11, 8),
          publishedAt: now.subtract(const Duration(days: 10)),
        ),
      ];
      final result = sortAds(ads, AdSortMode.relevance, now: now);
      expect(
        result.map((a) => a.id),
        ['featured', 'fresh', 'plain-near', 'plain-far'],
      );
    });

    test('does not mutate the input list', () {
      final ads = [
        ad(id: 'b', lastDate: DateTime(2026, 10, 18)),
        ad(id: 'a', lastDate: DateTime(2026, 10, 11)),
      ];
      sortAds(ads, AdSortMode.nearestDeadline, now: now);
      expect(ads.map((a) => a.id), ['b', 'a']);
    });
  });
}
