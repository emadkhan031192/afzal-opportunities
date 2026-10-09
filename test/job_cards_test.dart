import 'package:afzal_opportunities/core/l10n/app_localizations.dart';
import 'package:afzal_opportunities/models/advertisement.dart';
import 'package:afzal_opportunities/widgets/job_grid_card.dart';
import 'package:afzal_opportunities/widgets/job_list_card.dart';
import 'package:afzal_opportunities/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Advertisement _ad({DateTime? lastDate}) {
  return Advertisement(
    id: 'ad-1',
    title: 'Lecturer in Computer Science at the University of Mardan',
    organization: 'Abdul Wali Khan University',
    category: 'jobs',
    description: 'A detailed description of the advertised position.',
    status: 'published',
    lastDate: lastDate ?? DateTime.now().add(const Duration(days: 9)),
    publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
  );
}

Widget _wrap(Widget child, {double width = 390, double height = 844}) {
  return MaterialApp(
    localizationsDelegates: const [AppLocalizationsDelegate()],
    supportedLocales: const [Locale('en'), Locale('ur')],
    home: Scaffold(
      body: SizedBox(width: width, height: height, child: child),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  testWidgets('JobListCard renders without overflow', (tester) async {
    await tester.pumpWidget(
      _wrap(
        JobListCard(
          ad: _ad(),
          isSaved: false,
          onTap: () {},
          onToggleSave: () {},
        ),
        height: 200,
      ),
    );
    expect(find.textContaining('Lecturer'), findsOneWidget);
    expect(find.textContaining('days left'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('JobGridCard renders without overflow at phone width', (
    tester,
  ) async {
    // Simulate one grid cell at 2-column phone width.
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: (390 - 32 - 12) / 2,
          child: JobGridCard(ad: _ad(), onTap: () {}),
        ),
        height: 320,
      ),
    );
    expect(find.textContaining('days left'), findsOneWidget);
    expect(find.text('Jobs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SplashScreen renders and finishes on tap', (tester) async {
    var done = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en'), Locale('ur')],
        home: SplashScreen(onDone: () => done = true),
      ),
    );
    expect(find.text('AFZAL'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pump();
    expect(done, isTrue);
    expect(tester.takeException(), isNull);
  });
}
