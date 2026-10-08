import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Persists and exposes the user's theme choice (light / night mode).
class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  /// Loads the saved preference; defaults to light mode.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.themeModeKey);
    _mode = raw == _darkValue ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Switches between light and night mode and persists the choice.
  Future<void> toggle() async {
    await setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  /// Sets an explicit mode and persists the choice.
  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.themeModeKey,
      isDark ? _darkValue : _lightValue,
    );
  }

  static const String _darkValue = 'dark';
  static const String _lightValue = 'light';
}
