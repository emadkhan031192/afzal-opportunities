import 'package:afzal_opportunities/core/constants/app_constants.dart';
import 'package:afzal_opportunities/models/private_job.dart';
import 'package:afzal_opportunities/services/private_job_service.dart';
import 'package:flutter_test/flutter_test.dart';

PrivateJob _job({
  String id = 'j1',
  String city = 'Mardan',
  String approvalStatus = 'approved',
  bool active = true,
  DateTime? deadline,
  bool enableCall = false,
  bool enableWhatsapp = false,
  bool enableEmail = false,
  String? phone,
  String? whatsapp,
  String? email,
}) {
  return PrivateJob(
    id: id,
    title: 'Driver',
    company: 'ABC Transport',
    city: city,
    description: 'Full-time driver wanted.',
    deadline: deadline,
    applyPhone: phone,
    applyWhatsapp: whatsapp,
    applyEmail: email,
    enableCall: enableCall,
    enableWhatsapp: enableWhatsapp,
    enableEmail: enableEmail,
    approvalStatus: approvalStatus,
    active: active,
    postedBy: 'uid-1',
    postedByType: 'company',
  );
}

void main() {
  group('city filter', () {
    final jobs = [
      _job(id: 'a', city: 'Mardan'),
      _job(id: 'b', city: 'Peshawar'),
      _job(id: 'c', city: 'Mardan'),
    ];

    test('empty city returns everything', () {
      expect(filterPrivateJobsByCity(jobs, '').length, 3);
      expect(filterPrivateJobsByCity(jobs, 'all').length, 3);
    });

    test('a city keeps only its jobs', () {
      final filtered = filterPrivateJobsByCity(jobs, 'Mardan');
      expect(filtered.map((j) => j.id), ['a', 'c']);
    });

    test('unknown city returns nothing', () {
      expect(filterPrivateJobsByCity(jobs, 'Karachi'), isEmpty);
    });

    test('all 20 spec cities are offered', () {
      expect(AppConstants.kpkJobCities.length, 20);
      for (final city in [
        'Peshawar',
        'Mardan',
        'Swat',
        'Abbottabad',
        'Kohat',
        'Bannu',
        'Dera Ismail Khan',
        'Charsadda',
        'Nowshera',
        'Swabi',
        'Mansehra',
        'Haripur',
        'Malakand',
        'Dir',
        'Chitral',
        'Karak',
        'Hangu',
        'Lakki Marwat',
        'Tank',
        'Bajaur',
      ]) {
        expect(isValidJobCity(city), isTrue);
      }
      expect(isValidJobCity('Karachi'), isFalse);
    });
  });

  group('public feed filter', () {
    test('hides pending, rejected and inactive jobs', () {
      final jobs = [
        _job(id: 'live'),
        _job(id: 'pending', approvalStatus: 'pending'),
        _job(id: 'rejected', approvalStatus: 'rejected'),
        _job(id: 'inactive', active: false),
      ];
      final visible = PrivateJobService.applyPublicFilter(
        jobs,
        hideExpired: false,
      );
      expect(visible.map((j) => j.id), ['live']);
    });

    test('city filter composes with visibility', () {
      final jobs = [
        _job(id: 'mardan', city: 'Mardan'),
        _job(id: 'peshawar', city: 'Peshawar'),
      ];
      final visible = PrivateJobService.applyPublicFilter(
        jobs,
        city: 'Peshawar',
        hideExpired: false,
      );
      expect(visible.map((j) => j.id), ['peshawar']);
    });

    test('expired jobs are hidden by default', () {
      final jobs = [
        _job(id: 'old', deadline: DateTime(2020, 1, 1)),
        _job(id: 'new', deadline: DateTime(2999, 1, 1)),
      ];
      final visible = PrivateJobService.applyPublicFilter(jobs);
      expect(visible.map((j) => j.id), ['new']);
    });
  });

  group('at-least-one-apply-method validation', () {
    test('no enabled channel is invalid', () {
      expect(_job().hasValidApplyMethod, isFalse);
    });

    test('enabled channel with invalid details is invalid', () {
      expect(_job(enableCall: true, phone: '123').hasValidApplyMethod, isFalse);
      expect(
        _job(enableEmail: true, email: 'not-an-email').hasValidApplyMethod,
        isFalse,
      );
    });

    test('each enabled channel with valid details is valid', () {
      expect(
        _job(enableCall: true, phone: '0316 1185662').hasValidApplyMethod,
        isTrue,
      );
      expect(
        _job(enableWhatsapp: true, whatsapp: '03161185662').hasValidApplyMethod,
        isTrue,
      );
      expect(
        _job(enableEmail: true, email: 'hr@company.com').hasValidApplyMethod,
        isTrue,
      );
    });

    test('disabled channel details do not count', () {
      expect(
        _job(phone: '03161185662', whatsapp: '03161185662').hasValidApplyMethod,
        isFalse,
      );
    });
  });

  group('WhatsApp normalization', () {
    test('leading 0 becomes 92', () {
      final job = _job(enableWhatsapp: true, whatsapp: '0316 1185662');
      expect(job.whatsappInternational, '923161185662');
    });

    test('already-international numbers pass through', () {
      final job = _job(enableWhatsapp: true, whatsapp: '+92 316 1185662');
      expect(job.whatsappInternational, '923161185662');
    });

    test('disabled WhatsApp yields null', () {
      expect(_job(whatsapp: '03161185662').whatsappInternational, isNull);
    });
  });

  group('model parsing', () {
    test('public doc never carries contact details in toJson', () {
      final job = _job(
        enableCall: true,
        phone: '03161185662',
        enableWhatsapp: true,
        whatsapp: '03161185662',
        enableEmail: true,
        email: 'hr@company.com',
      );
      final json = job.toJson();
      expect(json.containsKey('applyPhone'), isFalse);
      expect(json.containsKey('applyWhatsapp'), isFalse);
      expect(json.containsKey('applyEmail'), isFalse);
      expect(json['enableCall'], isTrue);
      expect(json['enableWhatsapp'], isTrue);
      expect(json['enableEmail'], isTrue);
    });

    test('corrupt docs throw FormatException', () {
      expect(
        () => PrivateJob.fromJson('x', {'title': 'Only title'}),
        throwsFormatException,
      );
      expect(
        () => PrivateJob.fromJson('x', {
          'title': 'T',
          'company': 'C',
          'city': 'Mardan',
          'description': 'D',
          'postedBy': 'u',
          'approvalStatus': 'bogus',
        }),
        throwsFormatException,
      );
    });

    test('missing approvalStatus defaults to pending', () {
      final job = PrivateJob.fromJson('x', {
        'title': 'T',
        'company': 'C',
        'city': 'Mardan',
        'description': 'D',
        'postedBy': 'u',
      });
      expect(job.approvalStatus, 'pending');
      expect(job.isPubliclyVisible, isFalse);
    });
  });
}
