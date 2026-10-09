import 'package:flutter/material.dart';

import '../core/l10n/app_localizations.dart';
import '../core/l10n/locale_controller.dart';
import '../core/theme/theme_controller.dart';
import '../services/advertisement_service.dart';
import '../services/bookmark_service.dart';
import '../services/notification_service.dart';
import 'home/home_screen.dart';
import 'saved/saved_screen.dart';

/// Root scaffold: bottom navigation between the discovery feed and saved
/// advertisements. The branded header (logo, greeting, theme toggle) lives
/// inside the home feed itself.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.themeController,
    required this.localeController,
    required this.bookmarkService,
    required this.notificationService,
  });

  final ThemeController themeController;
  final LocaleController localeController;
  final BookmarkService bookmarkService;
  final NotificationService notificationService;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final AdvertisementService _service = AdvertisementService();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            HomeScreen(
              service: _service,
              bookmarks: widget.bookmarkService,
              themeController: widget.themeController,
              localeController: widget.localeController,
              notificationService: widget.notificationService,
              onOpenSaved: () => setState(() => _index = 1),
            ),
            SavedScreen(
              service: _service,
              bookmarks: widget.bookmarkService,
              onBrowse: () => setState(() => _index = 0),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: s.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bookmark_border),
            activeIcon: const Icon(Icons.bookmark),
            label: s.saved,
          ),
        ],
      ),
    );
  }
}
