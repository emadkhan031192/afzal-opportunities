import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'screens/main_shell.dart';
import 'services/bookmark_service.dart';

/// Root widget: wires MaterialApp to the persisted theme choice.
class AfzalApp extends StatefulWidget {
  const AfzalApp({
    super.key,
    required this.themeController,
    required this.bookmarkService,
  });

  final ThemeController themeController;
  final BookmarkService bookmarkService;

  @override
  State<AfzalApp> createState() => _AfzalAppState();
}

class _AfzalAppState extends State<AfzalApp> {
  @override
  void initState() {
    super.initState();
    widget.themeController.addListener(_handleThemeChanged);
  }

  @override
  void dispose() {
    widget.themeController.removeListener(_handleThemeChanged);
    super.dispose();
  }

  void _handleThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.nightTheme(),
      themeMode: widget.themeController.mode,
      home: MainShell(
        themeController: widget.themeController,
        bookmarkService: widget.bookmarkService,
      ),
    );
  }
}
