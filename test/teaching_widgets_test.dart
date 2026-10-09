import 'package:afzal_opportunities/core/l10n/app_localizations.dart';
import 'package:afzal_opportunities/models/teaching_vacancy.dart';
import 'package:afzal_opportunities/widgets/teaching_vacancy_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

TeachingVacancy _vacancy({bool withSalary = false}) {
  return TeachingVacancy(
    id: 'v-1',
    organizationId: 'org-1',
    ownerUid: 'uid-1',
    jobTitle: 'Mathematics Teacher for Grades 9 and 10',
    institutionName: 'City Grammar School',
    district: 'Mardan',
    city: 'Mardan',
    subjects: const ['Mathematics', 'Physics'],
    qualification: 'BS Mathematics',
    experienceRequired: '2 years teaching experience',
    description: 'Full-time position.',
    approvalStatus: TeachingApproval.approved,
    applicationDeadline: DateTime.now().add(const Duration(days: 12)),
    salaryMin: withSalary ? 30000 : null,
    salaryMax: withSalary ? 45000 : null,
    publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [AppLocalizationsDelegate()],
    supportedLocales: const [Locale('en'), Locale('ur')],
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  testWidgets('TeachingVacancyCard renders without overflow', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TeachingVacancyCard(
          vacancy: _vacancy(),
          isSaved: false,
          onTap: () {},
          onToggleSave: () {},
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Mathematics Teacher'), findsOneWidget);
    expect(find.textContaining('City Grammar School'), findsOneWidget);
    expect(find.textContaining('Mardan'), findsWidgets);
    expect(find.textContaining('days left'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TeachingVacancyCard shows salary only when provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TeachingVacancyCard(
          vacancy: _vacancy(withSalary: true),
          isSaved: true,
          onTap: () {},
          onToggleSave: () {},
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Rs 30,000'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TeachingVacancyCard renders in Urdu', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [AppLocalizationsDelegate()],
        supportedLocales: [Locale('en'), Locale('ur')],
        locale: Locale('ur'),
        home: _UrduCardHost(),
      ),
    );
    await tester.pump();
    // Urdu deadline label for ~12 days left.
    expect(find.textContaining('دن باقی'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _UrduCardHost extends StatelessWidget {
  const _UrduCardHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: TeachingVacancyCard(
          vacancy: _vacancy(),
          isSaved: false,
          onTap: () {},
          onToggleSave: () {},
        ),
      ),
    );
  }

  TeachingVacancy _vacancy() {
    return TeachingVacancy(
      id: 'v-1',
      organizationId: 'org-1',
      ownerUid: 'uid-1',
      jobTitle: 'Mathematics Teacher',
      institutionName: 'City Grammar School',
      district: 'Mardan',
      subjects: const ['Mathematics'],
      qualification: 'BS Mathematics',
      description: 'Full-time position.',
      approvalStatus: TeachingApproval.approved,
      applicationDeadline: DateTime.now().add(const Duration(days: 12)),
      publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
    );
  }
}
