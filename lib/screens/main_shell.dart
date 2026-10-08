import 'package:flutter/material.dart';

import '../core/theme/theme_controller.dart';
import '../services/advertisement_service.dart';
import '../services/bookmark_service.dart';
import 'home/home_screen.dart';
import 'saved/saved_screen.dart';

/// Root scaffold: bottom navigation between the discovery feed and saved
/// advertisements. The branded header (logo, greeting, theme toggle) lives
/// inside the home feed itself.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.themeController,
    required this.bookmarkService,
  });

  final ThemeController themeController;
  final BookmarkService bookmarkService;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final AdvertisementService _service = AdvertisementService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            HomeScreen(
              service: _service,
              bookmarks: widget.bookmarkService,
              themeController: widget.themeController,
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            activeIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
        ],
      ),
    );
  }
}
