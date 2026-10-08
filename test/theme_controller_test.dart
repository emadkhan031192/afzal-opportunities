import 'package:afzal_opportunities/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeController', () {
    test('starts in light mode by default', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = ThemeController();
      await controller.load();

      expect(controller.mode, ThemeMode.light);
      expect(controller.isDark, isFalse);
    });

    test('toggle switches to dark mode and persists it', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = ThemeController();
      await controller.load();

      await controller.toggle();
      expect(controller.mode, ThemeMode.dark);
      expect(controller.isDark, isTrue);

      final reloaded = ThemeController();
      await reloaded.load();
      expect(reloaded.mode, ThemeMode.dark);
    });

    test('toggle switches back to light mode', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'afzal_theme_mode': 'dark',
      });
      final controller = ThemeController();
      await controller.load();
      expect(controller.mode, ThemeMode.dark);

      await controller.toggle();
      expect(controller.mode, ThemeMode.light);

      final reloaded = ThemeController();
      await reloaded.load();
      expect(reloaded.mode, ThemeMode.light);
    });

    test('loads a previously saved dark mode', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'afzal_theme_mode': 'dark',
      });
      final controller = ThemeController();
      await controller.load();
      expect(controller.isDark, isTrue);
    });

    test('notifies listeners on change', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final controller = ThemeController();
      await controller.load();

      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.toggle();
      expect(notifications, greaterThan(0));
    });
  });
}
