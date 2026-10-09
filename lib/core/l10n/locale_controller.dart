import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Persists and exposes the user's language choice.
///
/// Values: 'system' (follow the device), 'en', 'ur'. A null [locale]
/// means "system" — MaterialApp then picks the best supported locale.
class LocaleController extends ChangeNotifier {
  String _choice = _systemValue;

  String get choice => _choice;

  /// The locale to pass to MaterialApp, or null for system default.
  Locale? get locale {
    switch (_choice) {
      case _englishValue:
        return const Locale('en');
      case _urduValue:
        return const Locale('ur');
      default:
        return null;
    }
  }

  bool get isUrduChoice => _choice == _urduValue;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.localeKey);
    if (raw == _englishValue || raw == _urduValue) {
      _choice = raw!;
    } else {
      _choice = _systemValue;
    }
    notifyListeners();
  }

  Future<void> setChoice(String choice) async {
    if (choice != _systemValue &&
        choice != _englishValue &&
        choice != _urduValue) {
      return;
    }
    if (_choice == choice) return;
    _choice = choice;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.localeKey, choice);
  }

  static const String _systemValue = 'system';
  static const String _englishValue = 'en';
  static const String _urduValue = 'ur';

  static const List<String> choices = [_systemValue, _englishValue, _urduValue];
}
