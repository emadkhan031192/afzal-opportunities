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
  int? salaryMin,
  int? salaryMax,
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
    salaryMin: salaryMin,
    salaryMax: salaryMax,
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
      final restored = TeachingOrganization.fromJson('o1', org.toJson());
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
        qualification: 'MA English',
      ),
      _vacancy(
        district: 'Mardan',
        subjects: ['Physics'],
        experience: '2 years teaching experience',
      ),
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
        deadline: DateTime.now().subtract(const Duration(days: 1)),
      );
      final future = _vacancy(
        deadline: DateTime.now().add(const Duration(days: 1)),
      );
      expect(TeachingService.isExpired(past), isTrue);
      expect(TeachingService.isExpired(future), isFalse);
      expect(TeachingService.isExpired(_vacancy()), isFalse);
    });
  });

  group('Application methods', () {
    TeachingVacancy withMethods({
      bool call = false,
      bool whatsapp = false,
      bool email = false,
      String? phone,
      String? wa,
      String? mail,
    }) {
      return TeachingVacancy(
        id: 'v1',
        organizationId: 'org1',
        ownerUid: 'uid1',
        jobTitle: 'Mathematics Teacher',
        institutionName: 'City Grammar School',
        district: 'Mardan',
        qualification: 'BS Mathematics',
        description: 'Full-time mathematics teacher.',
        approvalStatus: TeachingApproval.approved,
        applyPhone: phone,
        applyWhatsapp: wa,
        applyEmail: mail,
        enableCall: call,
        enableWhatsapp: whatsapp,
        enableEmail: email,
      );
    }

    test('validates phone numbers', () {
      expect(TeachingVacancy.isValidPhone('03161185662'), isTrue);
      expect(TeachingVacancy.isValidPhone('+92 316 1185662'), isTrue);
      expect(TeachingVacancy.isValidPhone('123'), isFalse);
      expect(TeachingVacancy.isValidPhone(''), isFalse);
      expect(TeachingVacancy.isValidPhone(null), isFalse);
    });

    test('validates email addresses', () {
      expect(TeachingVacancy.isValidEmail('school@example.com'), isTrue);
      expect(TeachingVacancy.isValidEmail('not-an-email'), isFalse);
      expect(TeachingVacancy.isValidEmail(''), isFalse);
      expect(TeachingVacancy.isValidEmail(null), isFalse);
    });

    test('canCall/canWhatsapp/canEmail respect enable flags', () {
      final v = withMethods(
        call: true,
        whatsapp: true,
        email: true,
        phone: '03161185662',
        wa: '03161185662',
        mail: 'school@example.com',
      );
      expect(v.canCall, isTrue);
      expect(v.canWhatsapp, isTrue);
      expect(v.canEmail, isTrue);

      // Enabled but invalid details → not usable.
      final bad = withMethods(call: true, phone: '123');
      expect(bad.canCall, isFalse);

      // Valid details but not enabled → not usable.
      final off = withMethods(phone: '03161185662');
      expect(off.canCall, isFalse);
    });

    test('hasValidApplyMethod requires at least one valid method', () {
      expect(withMethods().hasValidApplyMethod, isFalse);
      expect(
        withMethods(call: true, phone: '03161185662').hasValidApplyMethod,
        isTrue,
      );
      expect(
        withMethods(
          whatsapp: true,
          wa: '03161185662',
        ).hasValidApplyMethod,
        isTrue,
      );
      expect(
        withMethods(
          email: true,
          mail: 'school@example.com',
        ).hasValidApplyMethod,
        isTrue,
      );
    });

    test('legacy vacancies without new fields still load', () {
      final v = _vacancy();
      expect(v.enableCall, isFalse);
      expect(v.enableWhatsapp, isFalse);
      expect(v.enableEmail, isFalse);
      expect(v.canCall, isFalse);
      expect(v.hasValidApplyMethod, isFalse);
    });

    test('whatsappInternational normalizes Pakistani numbers', () {
      final v = withMethods(whatsapp: true, wa: '03161185662');
      expect(v.whatsappInternational, '923161185662');
      final intl = withMethods(whatsapp: true, wa: '+923161185662');
      expect(intl.whatsappInternational, '923161185662');
    });

    test('toJson excludes sensitive contact details', () {
      final v = withMethods(
        call: true,
        whatsapp: true,
        email: true,
        phone: '03161185662',
        wa: '03161185662',
        mail: 'school@example.com',
      );
      final json = v.toJson();
      expect(json.containsKey('applyPhone'), isFalse);
      expect(json.containsKey('applyWhatsapp'), isFalse);
      expect(json.containsKey('applyEmail'), isFalse);
      expect(json['enableCall'], isTrue);
      expect(json['enableWhatsapp'], isTrue);
      expect(json['enableEmail'], isTrue);
    });

    test('withContact merges private details', () {
      final v = withMethods(whatsapp: true);
      expect(v.canWhatsapp, isFalse);
      final merged = v.withContact(
        const VacancyContact(applyWhatsapp: '03161185662'),
      );
      expect(merged.canWhatsapp, isTrue);
      expect(merged.whatsappInternational, '923161185662');
    });

    test('VacancyContact round-trips through JSON', () {
      const c = VacancyContact(
        applyPhone: '03161185662',
        applyWhatsapp: '03161185662',
        applyEmail: 'school@example.com',
      );
      final restored = VacancyContact.fromJson(
        c.toJson('uid1')..remove('updatedAt'),
      );
      expect(restored.applyPhone, '03161185662');
      expect(restored.applyWhatsapp, '03161185662');
      expect(restored.applyEmail, 'school@example.com');
      expect(restored.isEmpty, isFalse);
      expect(const VacancyContact().isEmpty, isTrue);
    });
  });
}
