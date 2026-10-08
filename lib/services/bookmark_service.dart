import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

/// Local bookmarks, persisted across app restarts.
///
/// Bookmarks are keyed by stable advertisement id. No account is required
/// in v1.0.
class BookmarkService extends ChangeNotifier {
  List<String> _ids = [];
  bool _loaded = false;

  /// Bookmarked advertisement ids (unmodifiable copy).
  List<String> get ids => List<String>.unmodifiable(_ids);

  bool get isLoaded => _loaded;

  /// Loads persisted bookmarks. Safe to call once at startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _ids = prefs.getStringList(AppConstants.bookmarksKey) ?? <String>[];
    _loaded = true;
    notifyListeners();
  }

  bool isBookmarked(String id) => _ids.contains(id);

  /// Adds [id] when missing, removes it when present, then persists.
  Future<void> toggle(String id) async {
    if (_ids.contains(id)) {
      _ids.remove(id);
    } else {
      _ids.add(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.bookmarksKey, _ids);
  }
}
