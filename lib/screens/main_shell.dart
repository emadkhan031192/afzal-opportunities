import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/theme_controller.dart';
import '../services/advertisement_service.dart';
import '../services/bookmark_service.dart';
import 'home/home_screen.dart';
import 'saved/saved_screen.dart';

/// Root scaffold: branded app bar with theme toggle + bottom navigation.
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.appName,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            Text(
              AppConstants.brandName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        actions: [
          AnimatedBuilder(
            animation: widget.themeController,
            builder: (context, _) {
              final isDark = widget.themeController.isDark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                tooltip: isDark
                    ? 'Switch to light mode'
                    : 'Switch to night mode',
                onPressed: widget.themeController.toggle,
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            service: _service,
            bookmarks: widget.bookmarkService,
          ),
          SavedScreen(
            service: _service,
            bookmarks: widget.bookmarkService,
          ),
        ],
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
