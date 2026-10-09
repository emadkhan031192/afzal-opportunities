import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_constants.dart';
import 'core/l10n/app_localizations.dart';
import 'core/l10n/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'screens/main_shell.dart';
import 'screens/splash/splash_screen.dart';
import 'services/bookmark_service.dart';
import 'services/notification_service.dart';

/// Root widget: wires MaterialApp to the persisted theme and locale choices.
class AfzalApp extends StatefulWidget {
  const AfzalApp({
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
  State<AfzalApp> createState() => _AfzalAppState();
}

class _AfzalAppState extends State<AfzalApp> {
  @override
  void initState() {
    super.initState();
    widget.themeController.addListener(_handleChanged);
    widget.localeController.addListener(_handleChanged);
  }

  @override
  void dispose() {
    widget.themeController.removeListener(_handleChanged);
    widget.localeController.removeListener(_handleChanged);
    super.dispose();
  }

  void _handleChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.nightTheme(),
      themeMode: widget.themeController.mode,
      locale: widget.localeController.locale,
      supportedLocales: const [Locale('en'), Locale('ur')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _LaunchFlow(
        themeController: widget.themeController,
        localeController: widget.localeController,
        bookmarkService: widget.bookmarkService,
        teachingBookmarks: widget.teachingBookmarks,
        notificationService: widget.notificationService,
      ),
    );
  }
}

/// Shows the branded splash screen first, then the main app shell.
class _LaunchFlow extends StatefulWidget {
  const _LaunchFlow({
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
  State<_LaunchFlow> createState() => _LaunchFlowState();
}

class _LaunchFlowState extends State<_LaunchFlow> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashScreen(onDone: () => setState(() => _splashDone = true));
    }
    return MainShell(
      themeController: widget.themeController,
      localeController: widget.localeController,
      bookmarkService: widget.bookmarkService,
      teachingBookmarks: widget.teachingBookmarks,
      notificationService: widget.notificationService,
    );
  }
}
