import 'package:afzal_opportunities/app.dart';
import 'package:afzal_opportunities/core/constants/app_constants.dart';
import 'package:afzal_opportunities/core/l10n/locale_controller.dart';
import 'package:afzal_opportunities/core/theme/theme_controller.dart';
import 'package:afzal_opportunities/services/bookmark_service.dart';
import 'package:afzal_opportunities/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'smoke: home shows branded header and demo ads, card opens details',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final themeController = ThemeController();
      await themeController.load();
      final localeController = LocaleController();
      await localeController.load();
      final bookmarks = BookmarkService();
      await bookmarks.load();
      final teachingBookmarks = BookmarkService(
        storageKey: AppConstants.teachingBookmarksKey,
      );
      await teachingBookmarks.load();

      await tester.pumpWidget(
        AfzalApp(
          themeController: themeController,
          localeController: localeController,
          bookmarkService: bookmarks,
          teachingBookmarks: teachingBookmarks,
          notificationService: NotificationService(),
        ),
      );
      await tester.pumpAndSettle();

      // Branded header and demo-mode advertisements are visible.
      expect(find.textContaining('Afzal'), findsWidgets);
      expect(find.textContaining('Lady Health Visitor'), findsWidgets);

      // Tapping a card navigates to the details screen.
      await tester.tap(find.textContaining('Lady Health Visitor').first);
      await tester.pumpAndSettle();

      expect(
        find.text('Lady Health Visitor (LHV) Recruitment 2026'),
        findsWidgets,
      );
      expect(find.text('Description'), findsWidgets);

      // System back navigation returns to the feed.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Latest advertisements'), findsWidgets);
    },
  );
}
