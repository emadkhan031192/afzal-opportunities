import 'package:afzal_opportunities/core/utils/whatsapp_templates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhatsappTemplates', () {
    test('fills placeholders with real values', () {
      final msg = WhatsappTemplates.fill(
        version: 0,
        urdu: false,
        jobTitle: 'Mathematics Teacher',
        schoolName: 'City Grammar School',
        city: 'Mardan',
      );
      expect(msg.contains('[Job Title]'), isFalse);
      expect(msg.contains('[School Name]'), isFalse);
      expect(msg.contains('[City]'), isFalse);
      expect(msg.contains('Mathematics Teacher'), isTrue);
      expect(msg.contains('City Grammar School'), isTrue);
      expect(msg.contains('Mardan'), isTrue);
    });

    test('all six templates fill correctly', () {
      for (var version = 0; version < 3; version++) {
        for (final urdu in [false, true]) {
          final msg = WhatsappTemplates.fill(
            version: version,
            urdu: urdu,
            jobTitle: 'Science Teacher',
            schoolName: 'The City School',
            city: 'Peshawar',
          );
          expect(
            msg.contains('['),
            isFalse,
            reason: 'version $version urdu=$urdu has unfilled placeholder',
          );
          expect(msg.contains('Science Teacher'), isTrue);
          expect(msg.contains('The City School'), isTrue);
          expect(msg.contains('Peshawar'), isTrue);
        }
      }
    });

    test('Urdu templates use Urdu script', () {
      final msg = WhatsappTemplates.fill(
        version: 0,
        urdu: true,
        jobTitle: 'Teacher',
        schoolName: 'School',
        city: 'Mardan',
      );
      expect(msg.contains('السلام علیکم'), isTrue);
    });

    test('version is clamped to valid range', () {
      final msg = WhatsappTemplates.fill(
        version: 99,
        urdu: false,
        jobTitle: 'T',
        schoolName: 'S',
        city: 'C',
      );
      expect(msg.contains('['), isFalse);
    });
  });
}
