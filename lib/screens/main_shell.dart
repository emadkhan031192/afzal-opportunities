import 'package:flutter/material.dart';

import '../core/l10n/app_localizations.dart';
import '../core/l10n/locale_controller.dart';
import '../core/theme/theme_controller.dart';
import '../services/advertisement_service.dart';
import '../services/bookmark_service.dart';
import '../services/notification_service.dart';
import '../services/teaching_service.dart';
import '../widgets/whatsapp_fab.dart';
import 'home/home_screen.dart';
import 'saved/saved_screen.dart';
import 'teaching/teaching_screen.dart';

/// Root scaffold: bottom navigation between the discovery feed, teaching
/// jobs and saved advertisements. The branded header lives inside each
/// feed.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.themeController,
    required this.localeController,
    required this.bookmarkService,
    required this.teachingBookmarks,
    required this.notificationService,
  });

  final ThemeController themeController;
  final LocaleController localeController;
  final BookmarkService bookmarkService;
  final BookmarkService teachingBookmarks;
  final NotificationService notificationService;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final AdvertisementService _service = AdvertisementService();
  final TeachingService _teachingService = TeachingService();

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
              onOpenSaved: () => setState(() => _index = 2),
            ),
            TeachingScreen(
              service: _teachingService,
              bookmarks: widget.bookmarkService,
              teachingBookmarks: widget.teachingBookmarks,
              themeController: widget.themeController,
              localeController: widget.localeController,
              notificationService: widget.notificationService,
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
            icon: const Icon(Icons.school_outlined),
            activeIcon: const Icon(Icons.school),
            label: s.teaching,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bookmark_border),
            activeIcon: const Icon(Icons.bookmark),
            label: s.saved,
          ),
        ],
      ),
      floatingActionButton: const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: WhatsAppFab(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
