import 'package:afzal_opportunities/core/utils/deadline.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime utc(int year, int month, int day, [int hour = 0, int minute = 0]) {
  return DateTime.utc(year, month, day, hour, minute);
}

void main() {
  group('getDeadlineInfo', () {
    test('null lastDate shows LAST DATE NOT SPECIFIED', () {
      final info = getDeadlineInfo(now: utc(2026, 10, 8, 12));
      expect(info.label, 'LAST DATE NOT SPECIFIED');
      expect(info.isExpired, isFalse);
      expect(info.daysLeft, isNull);
      expect(info.tone, DeadlineTone.neutral);
    });

    test('past lastDate shows EXPIRED', () {
      final info = getDeadlineInfo(
        lastDate: DateTime(2026, 10, 5),
        now: utc(2026, 10, 8, 12),
      );
      expect(info.label, 'EXPIRED');
      expect(info.isExpired, isTrue);
      expect(info.tone, DeadlineTone.danger);
    });

    test('last date today stays active through the day', () {
      // 06:00 UTC == 11:00 PKT on 2026-10-08.
      final info = getDeadlineInfo(
        lastDate: DateTime(2026, 10, 8),
        now: utc(2026, 10, 8, 6),
      );
      expect(info.label, 'LAST DATE TODAY');
      expect(info.isExpired, isFalse);
      expect(info.daysLeft, 0);
    });

    test(
      'PKT boundary: 23:30 PKT on last date active, 00:30 PKT next day expired',
      () {
        final lastDate = DateTime(2026, 10, 8);
        // 18:30 UTC == 23:30 PKT on the last date: still active.
        final stillActive = getDeadlineInfo(
          lastDate: lastDate,
          now: utc(2026, 10, 8, 18, 30),
        );
        expect(stillActive.isExpired, isFalse);
        expect(stillActive.label, 'LAST DATE TODAY');

        // 19:30 UTC == 00:30 PKT the next day: expired.
        final expired = getDeadlineInfo(
          lastDate: lastDate,
          now: utc(2026, 10, 8, 19, 30),
        );
        expect(expired.isExpired, isTrue);
        expect(expired.label, 'EXPIRED');
      },
    );

    test('one day ahead shows CLOSING TOMORROW', () {
      final info = getDeadlineInfo(
        lastDate: DateTime(2026, 10, 9),
        now: utc(2026, 10, 8, 12),
      );
      expect(info.label, 'CLOSING TOMORROW');
      expect(info.isExpired, isFalse);
      expect(info.daysLeft, 1);
      expect(info.tone, DeadlineTone.warning);
    });

    test('2 to 7 days ahead shows CLOSING SOON', () {
      for (final days in [2, 3, 7]) {
        final info = getDeadlineInfo(
          lastDate: DateTime(2026, 10, 8).add(Duration(days: days)),
          now: utc(2026, 10, 8, 12),
        );
        expect(info.label, 'CLOSING SOON', reason: 'for $days days');
        expect(info.daysLeft, days);
        expect(info.tone, DeadlineTone.warning);
      }
    });

    test('more than 7 days ahead shows N DAYS LEFT', () {
      final info = getDeadlineInfo(
        lastDate: DateTime(2026, 10, 18),
        now: utc(2026, 10, 8, 12),
      );
      expect(info.label, '10 DAYS LEFT');
      expect(info.isExpired, isFalse);
      expect(info.daysLeft, 10);
      expect(info.tone, DeadlineTone.success);
    });

    test('published within 72 hours and active counts as NEW', () {
      final now = utc(2026, 10, 8, 12);
      final info = getDeadlineInfo(
        lastDate: DateTime(2026, 10, 20),
        publishedAt: now.subtract(const Duration(hours: 5)),
        now: now,
      );
      expect(info.isNew, isTrue);
    });

    test('published 4 days ago is not NEW', () {
      final now = utc(2026, 10, 8, 12);
      final info = getDeadlineInfo(
        lastDate: DateTime(2026, 10, 20),
        publishedAt: now.subtract(const Duration(days: 4)),
        now: now,
      );
      expect(info.isNew, isFalse);
    });

    test('expired advertisement is never NEW', () {
      final now = utc(2026, 10, 8, 12);
      final info = getDeadlineInfo(
        lastDate: DateTime(2026, 10, 5),
        publishedAt: now.subtract(const Duration(hours: 2)),
        now: now,
      );
      expect(info.isNew, isFalse);
      expect(info.isExpired, isTrue);
    });

    test('advertisement without deadline can still be NEW', () {
      final now = utc(2026, 10, 8, 12);
      final info = getDeadlineInfo(
        publishedAt: now.subtract(const Duration(hours: 1)),
        now: now,
      );
      expect(info.isNew, isTrue);
      expect(info.label, 'LAST DATE NOT SPECIFIED');
    });
  });

  group('pktNow', () {
    test('converts to UTC+5 with no DST', () {
      expect(pktNow(utc(2026, 1, 15, 12)), utc(2026, 1, 15, 17));
      expect(pktNow(utc(2026, 7, 15, 12)), utc(2026, 7, 15, 17));
    });
  });
}
