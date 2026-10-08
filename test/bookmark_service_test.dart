import 'package:afzal_opportunities/services/bookmark_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BookmarkService', () {
    test('toggle adds then removes a bookmark', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final service = BookmarkService();
      await service.load();

      expect(service.isBookmarked('ad-1'), isFalse);

      await service.toggle('ad-1');
      expect(service.isBookmarked('ad-1'), isTrue);
      expect(service.ids, contains('ad-1'));

      await service.toggle('ad-1');
      expect(service.isBookmarked('ad-1'), isFalse);
      expect(service.ids, isNot(contains('ad-1')));
    });

    test('bookmarks persist across service instances', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final first = BookmarkService();
      await first.load();
      await first.toggle('ad-1');
      await first.toggle('ad-2');

      final second = BookmarkService();
      await second.load();
      expect(second.isBookmarked('ad-1'), isTrue);
      expect(second.isBookmarked('ad-2'), isTrue);

      await second.toggle('ad-1');
      final third = BookmarkService();
      await third.load();
      expect(third.isBookmarked('ad-1'), isFalse);
      expect(third.isBookmarked('ad-2'), isTrue);
    });

    test('notifies listeners on toggle', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final service = BookmarkService();
      await service.load();

      var notifications = 0;
      service.addListener(() => notifications++);

      await service.toggle('ad-9');
      expect(notifications, greaterThan(0));
    });
  });
}
