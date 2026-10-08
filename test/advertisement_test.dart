import 'package:afzal_opportunities/models/advertisement.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> validJson() {
  return <String, dynamic>{
    'title': 'Primary School Teacher Jobs 2026',
    'organization': 'Education Department, KP',
    'category': 'jobs',
    'description': 'Test description.',
    'status': 'published',
    'location': 'Peshawar',
    'lastDate': '2026-12-31',
    'publishedAt': '2026-10-01T10:00:00Z',
    'isFeatured': false,
  };
}

void main() {
  group('Advertisement.fromJson', () {
    test('parses valid JSON', () {
      final ad = Advertisement.fromJson('abc', validJson());
      expect(ad.id, 'abc');
      expect(ad.title, 'Primary School Teacher Jobs 2026');
      expect(ad.organization, 'Education Department, KP');
      expect(ad.category, 'jobs');
      expect(ad.status, 'published');
      expect(ad.location, 'Peshawar');
      expect(ad.lastDate, DateTime(2026, 12, 31));
      expect(ad.publishedAt, DateTime.utc(2026, 10, 1, 10));
      expect(ad.isFeatured, isFalse);
    });

    test('missing title throws FormatException', () {
      final json = validJson()..remove('title');
      expect(
        () => Advertisement.fromJson('x', json),
        throwsFormatException,
      );
    });

    test('blank organization throws FormatException', () {
      final json = validJson()..['organization'] = '   ';
      expect(
        () => Advertisement.fromJson('x', json),
        throwsFormatException,
      );
    });

    test('invalid category throws FormatException', () {
      final json = validJson()..['category'] = 'lottery';
      expect(
        () => Advertisement.fromJson('x', json),
        throwsFormatException,
      );
    });

    test('missing description throws FormatException', () {
      final json = validJson()..remove('description');
      expect(
        () => Advertisement.fromJson('x', json),
        throwsFormatException,
      );
    });

    test('invalid status throws FormatException', () {
      final json = validJson()..['status'] = 'deleted';
      expect(
        () => Advertisement.fromJson('x', json),
        throwsFormatException,
      );
    });

    test('missing status defaults to draft', () {
      final json = validJson()..remove('status');
      final ad = Advertisement.fromJson('x', json);
      expect(ad.status, 'draft');
    });

    test('malformed lastDate throws FormatException', () {
      for (final bad in ['31-12-2026', '2026/12/31', 'soon', '2026-13-01']) {
        final json = validJson()..['lastDate'] = bad;
        expect(
          () => Advertisement.fromJson('x', json),
          throwsFormatException,
          reason: 'for "$bad"',
        );
      }
    });

    test('null lastDate is accepted', () {
      final json = validJson()..['lastDate'] = null;
      final ad = Advertisement.fromJson('x', json);
      expect(ad.lastDate, isNull);
    });

    test('Firestore Timestamp lastDate is accepted (date part only)', () {
      final json = validJson();
      json['lastDate'] = Timestamp.fromDate(DateTime.utc(2026, 12, 31, 15, 30));
      final ad = Advertisement.fromJson('x', json);
      expect(ad.lastDate, DateTime(2026, 12, 31));
    });

    test('DateTime lastDate keeps the date part only', () {
      final json = validJson()..['lastDate'] = DateTime(2026, 12, 31, 23, 45);
      final ad = Advertisement.fromJson('x', json);
      expect(ad.lastDate, DateTime(2026, 12, 31));
    });
  });

  group('Advertisement.isActiveAt', () {
    // 12:00 UTC == 17:00 PKT on 2026-10-08.
    final now = DateTime.utc(2026, 10, 8, 12);

    test('published ad with future deadline is active', () {
      final ad = Advertisement.fromJson('x', validJson());
      expect(ad.isActiveAt(now), isTrue);
    });

    test('expired ad is not active', () {
      final json = validJson()..['lastDate'] = '2026-10-01';
      final ad = Advertisement.fromJson('x', json);
      expect(ad.isActiveAt(now), isFalse);
    });

    test('draft ad is not active', () {
      final json = validJson()..['status'] = 'draft';
      final ad = Advertisement.fromJson('x', json);
      expect(ad.isActiveAt(now), isFalse);
    });

    test('archived ad is not active', () {
      final json = validJson()..['status'] = 'archived';
      final ad = Advertisement.fromJson('x', json);
      expect(ad.isActiveAt(now), isFalse);
    });

    test('published ad without deadline stays active', () {
      final json = validJson()..['lastDate'] = null;
      final ad = Advertisement.fromJson('x', json);
      expect(ad.isActiveAt(now), isTrue);
    });

    test('ad stays active through 23:59 PKT on its last date', () {
      final json = validJson()..['lastDate'] = '2026-10-08';
      final ad = Advertisement.fromJson('x', json);
      // 18:30 UTC == 23:30 PKT on the last date.
      expect(ad.isActiveAt(DateTime.utc(2026, 10, 8, 18, 30)), isTrue);
      // 19:30 UTC == 00:30 PKT the next day.
      expect(ad.isActiveAt(DateTime.utc(2026, 10, 8, 19, 30)), isFalse);
    });
  });

  group('Advertisement.toJson', () {
    test('round-trips through fromJson', () {
      final original = Advertisement.fromJson('abc', validJson());
      final restored = Advertisement.fromJson('abc', original.toJson());
      expect(restored.title, original.title);
      expect(restored.lastDate, original.lastDate);
      expect(restored.status, original.status);
      expect(restored.category, original.category);
    });
  });
}
