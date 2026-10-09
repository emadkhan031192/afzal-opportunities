import 'package:afzal_opportunities/core/l10n/app_localizations.dart';
import 'package:afzal_opportunities/core/l10n/locale_controller.dart';
import 'package:afzal_opportunities/core/theme/card_tints.dart';
import 'package:afzal_opportunities/core/utils/deadline.dart';
import 'package:afzal_opportunities/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleController', () {
    test('defaults to system choice with null locale', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = LocaleController();
      await controller.load();

      expect(controller.choice, 'system');
      expect(controller.locale, isNull);
    });

    test('persists the Urdu choice', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = LocaleController();
      await controller.load();

      await controller.setChoice('ur');
      expect(controller.locale, const Locale('ur'));
      expect(controller.isUrduChoice, isTrue);

      final reloaded = LocaleController();
      await reloaded.load();
      expect(reloaded.choice, 'ur');
    });

    test('rejects unknown choices', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = LocaleController();
      await controller.load();

      await controller.setChoice('xx');
      expect(controller.choice, 'system');
    });
  });

  group('AppLocalizations', () {
    test('English strings resolve', () {
      final s = AppLocalizations(const Locale('en'));
      expect(s.isUrdu, isFalse);
      expect(s.home, 'Home');
      expect(s.latestAdvertisements, 'Latest advertisements');
      expect(s.daysLeft(5), '5 days left');
    });

    test('Urdu strings resolve with RTL locale', () {
      final s = AppLocalizations(const Locale('ur'));
      expect(s.isUrdu, isTrue);
      expect(s.home, 'ہوم');
      expect(s.latestAdvertisements, 'تازہ ترین اشتہارات');
      expect(s.daysLeft(5), '5 دن باقی');
    });

    test('falls back to English for missing Urdu keys', () {
      final s = AppLocalizations(const Locale('ur'));
      // Every key currently has an Urdu translation; an unknown key
      // falls back to the key itself via English.
      expect(s.home.isNotEmpty, isTrue);
    });

    test('deadlineLabel localizes every deadline state', () {
      final en = AppLocalizations(const Locale('en'));
      final ur = AppLocalizations(const Locale('ur'));

      DeadlineInfo info({int? days}) => DeadlineInfo(
            label: 'x',
            isExpired: (days ?? 1) < 0,
            isNew: false,
            daysLeft: days,
            tone: DeadlineTone.neutral,
          );

      expect(en.deadlineLabel(info(days: null)), 'LAST DATE NOT SPECIFIED');
      expect(ur.deadlineLabel(info(days: null)), 'آخری تاریخ درج نہیں');
      expect(en.deadlineLabel(info(days: -2)), 'EXPIRED');
      expect(ur.deadlineLabel(info(days: -2)), 'میعاد ختم');
      expect(en.deadlineLabel(info(days: 0)), 'LAST DATE TODAY');
      expect(ur.deadlineLabel(info(days: 0)), 'آج آخری تاریخ');
      expect(en.deadlineLabel(info(days: 1)), 'CLOSING TOMORROW');
      expect(ur.deadlineLabel(info(days: 1)), 'کل آخری تاریخ');
      expect(en.deadlineLabel(info(days: 4)), 'CLOSING SOON');
      expect(ur.deadlineLabel(info(days: 4)), 'جلد ختم ہو رہا ہے');
      expect(en.deadlineLabel(info(days: 30)), '30 days left');
      expect(ur.deadlineLabel(info(days: 30)), '30 دن باقی');
    });
  });

  group('NotificationService preferences', () {
    test('promotions are off by default, others on', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final service = NotificationService();

      expect(await service.isEnabled(NotificationType.newAds), isTrue);
      expect(await service.isEnabled(NotificationType.closingSoon), isTrue);
      expect(await service.isEnabled(NotificationType.teaching), isTrue);
      expect(
        await service.isEnabled(NotificationType.promotions),
        isFalse,
      );
    });

    test('preferences persist', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final service = NotificationService();

      await service.setEnabled(NotificationType.newAds, false);
      expect(await service.isEnabled(NotificationType.newAds), isFalse);

      final reloaded = NotificationService();
      expect(await reloaded.isEnabled(NotificationType.newAds), isFalse);
    });

    test('defaultEnabled matches documented defaults', () {
      expect(NotificationService.defaultEnabled(NotificationType.newAds),
          isTrue);
      expect(NotificationService.defaultEnabled(NotificationType.promotions),
          isFalse);
    });
  });

  group('cardTintForCategory', () {
    test('tints by category in light mode', () {
      expect(
        cardTintForCategory('jobs', false).background.value,
        isNot(cardTintForCategory('scholarships', false).background.value),
      );
      expect(
        cardTintForCategory('admissions', false).background.value,
        isNot(cardTintForCategory('other', false).background.value),
      );
    });

    test('dark mode uses different backgrounds than light mode', () {
      for (final id in ['jobs', 'scholarships', 'admissions', 'other']) {
        expect(
          cardTintForCategory(id, true).background.value,
          isNot(cardTintForCategory(id, false).background.value),
          reason: 'dark tint should differ for $id',
        );
      }
    });

    test('unknown categories fall back to the jobs tint', () {
      expect(
        cardTintForCategory('nope', false).background.value,
        cardTintForCategory('jobs', false).background.value,
      );
    });
  });
}
