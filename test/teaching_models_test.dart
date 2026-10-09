import 'package:afzal_opportunities/models/teaching_accounts.dart';
import 'package:afzal_opportunities/models/teaching_vacancy.dart';
import 'package:afzal_opportunities/services/teaching_service.dart';
import 'package:flutter_test/flutter_test.dart';

TeachingVacancy _vacancy({
  String district = 'Mardan',
  List<String> subjects = const ['Mathematics'],
  String qualification = 'BS Mathematics',
  String? experience,
  DateTime? deadline,
}) {
  return TeachingVacancy(
    id: 'v1',
    organizationId: 'org1',
    ownerUid: 'uid1',
    jobTitle: 'Mathematics Teacher',
    institutionName: 'City Grammar School',
    district: district,
    qualification: qualification,
    description: 'Full-time mathematics teacher for grades 9-10.',
    approvalStatus: TeachingApproval.approved,
    subjects: subjects,
    experienceRequired: experience,
    applicationDeadline: deadline,
  );
}

void main() {
  group('TeachingVacancy model', () {
    test('round-trips through JSON', () {
      final v = _vacancy(salaryMin: null, salaryMax: null);
      final restored = TeachingVacancy.fromJson(
        'v1',
        v.toJson()..['salaryMin'] = 30000,
      );
      expect(restored.jobTitle, 'Mathematics Teacher');
      expect(restored.subjects, ['Mathematics']);
      expect(restored.salaryDisplay, 'Rs 30,000');
    });

    test('salaryDisplay formats ranges and nulls', () {
      expect(_vacancy().salaryDisplay, isNull);
      final range = TeachingVacancy(
        id: 'v',
        organizationId: 'o',
        ownerUid: 'u',
        jobTitle: 't',
        institutionName: 'i',
        district: 'd',
        qualification: 'q',
        description: 'd',
        approvalStatus: TeachingApproval.pending,
        salaryMin: 30000,
        salaryMax: 45000,
      );
      expect(range.salaryDisplay, 'Rs 30,000 – 45,000');
    });

    test('rejects invalid approvalStatus', () {
      expect(
        () => TeachingVacancy.fromJson('v1', {
          'jobTitle': 't',
          'institutionName': 'i',
          'district': 'd',
          'qualification': 'q',
          'description': 'd',
          'ownerUid': 'u',
          'approvalStatus': 'bogus',
        }),
        throwsFormatException,
      );
    });

    test('rejects missing required fields', () {
      expect(
        () => TeachingVacancy.fromJson('v1', {'jobTitle': 't'}),
        throwsFormatException,
      );
    });
  });

  group('TeachingOrganization model', () {
    test('round-trips and keeps contact details', () {
      final org = TeachingOrganization(
        id: 'o1',
        ownerUid: 'u1',
        institutionName: 'City Grammar School',
        institutionType: 'School',
        contactPerson: 'Ahmed Khan',
        email: 'info@citygrammar.test',
        district: 'Mardan',
        contactNumber: '03001234567',
        approvalStatus: TeachingApproval.pending,
      );
      final restored =
          TeachingOrganization.fromJson('o1', org.toJson());
      expect(restored.institutionName, 'City Grammar School');
      expect(restored.contactNumber, '03001234567');
      expect(restored.isPending, isTrue);
    });
  });

  group('TeacherProfile model', () {
    test('profiles are private by default', () {
      final profile = TeacherProfile(
        id: 't1',
        ownerUid: 'u2',
        fullName: 'Sara Ahmed',
        email: 'sara@test.example',
        district: 'Peshawar',
        approvalStatus: TeachingApproval.pending,
      );
      expect(profile.profileVisibility, 'private');
      expect(profile.hasCv, isFalse);
      final restored = TeacherProfile.fromJson('t1', profile.toJson());
      expect(restored.profileVisibility, 'private');
    });

    test('rejects invalid visibility', () {
      expect(
        () => TeacherProfile.fromJson('t1', {
          'ownerUid': 'u',
          'fullName': 'n',
          'email': 'e',
          'district': 'd',
          'profileVisibility': 'everyone',
        }),
        throwsFormatException,
      );
    });
  });

  group('TeachingService.applyFilter', () {
    final vacancies = [
      _vacancy(district: 'Mardan', subjects: ['Mathematics']),
      _vacancy(
          district: 'Peshawar',
          subjects: ['English'],
          qualification: 'MA English'),
      _vacancy(
          district: 'Mardan',
          subjects: ['Physics'],
          experience: '2 years teaching experience'),
    ];

    test('filters by district', () {
      final out = TeachingService.applyFilter(
        vacancies,
        const VacancyFilter(district: 'Mardan'),
      );
      expect(out.length, 2);
    });

    test('filters by subject (case-insensitive)', () {
      final out = TeachingService.applyFilter(
        vacancies,
        const VacancyFilter(subject: 'english'),
      );
      expect(out.length, 1);
      expect(out.first.district, 'Peshawar');
    });

    test('filters by qualification substring', () {
      final out = TeachingService.applyFilter(
        vacancies,
        const VacancyFilter(qualification: 'ma english'),
      );
      expect(out.length, 1);
    });

    test('searches across title, institution, district and subjects', () {
      final out = TeachingService.applyFilter(
        vacancies,
        const VacancyFilter(query: 'physics'),
      );
      expect(out.length, 1);
      final org = TeachingService.applyFilter(
        vacancies,
        const VacancyFilter(query: 'city grammar'),
      );
      expect(org.length, 3);
    });

    test('hides expired vacancies by default', () {
      final list = [
        _vacancy(deadline: DateTime.now().subtract(const Duration(days: 2))),
        _vacancy(deadline: DateTime.now().add(const Duration(days: 10))),
      ];
      final hidden = TeachingService.applyFilter(list, const VacancyFilter());
      expect(hidden.length, 1);
      final shown = TeachingService.applyFilter(
        list,
        const VacancyFilter(hideExpired: false),
      );
      expect(shown.length, 2);
    });

    test('isExpired uses PKT day boundaries', () {
      final past = _vacancy(
          deadline: DateTime.now().subtract(const Duration(days: 1)));
      final future = _vacancy(
          deadline: DateTime.now().add(const Duration(days: 1)));
      expect(TeachingService.isExpired(past), isTrue);
      expect(TeachingService.isExpired(future), isFalse);
      expect(TeachingService.isExpired(_vacancy()), isFalse);
    });
  });
}
