import 'package:intl/intl.dart';

import '../constants/app_constants.dart';
import '../l10n/app_localizations.dart';
import '../utils/deadline.dart';
import '../../models/advertisement.dart';
import '../../models/teaching_vacancy.dart';

/// Builds the full WhatsApp share message: the ad/vacancy details followed
/// by the Afzal E Services contact footer (WhatsApp *bold* formatting).
String buildAdShareText(
  Advertisement ad,
  AppLocalizations s, {
  bool forWhatsApp = true,
}) {
  final info = getDeadlineInfo(
    lastDate: ad.lastDate,
    publishedAt: ad.publishedAt,
  );
  final deadlineLine = ad.lastDate != null
      ? '${s.lastDate}: ${DateFormat('d MMMM yyyy').format(ad.lastDate!)} '
            '(${s.deadlineLabel(info)})'
      : '${s.lastDate}: ${s.notSpecified}';
  final link = (ad.sourceUrl ?? '').trim().isNotEmpty
      ? ad.sourceUrl!.trim()
      : (ad.applicationUrl ?? '').trim();

  final b = forWhatsApp ? '*' : '';
  final text = StringBuffer()
    ..writeln('$b${ad.title}$b')
    ..writeln(ad.organization)
    ..writeln(deadlineLine);
  if (link.isNotEmpty) {
    text.writeln(link);
  }
  final desc = ad.description.trim();
  if (desc.isNotEmpty) {
    text
      ..writeln()
      ..writeln(_shortDescription(desc));
  }
  text
    ..writeln()
    ..writeln(_footer());
  return text.toString().trim();
}

/// Builds the full WhatsApp share message for a teaching vacancy.
String buildVacancyShareText(TeachingVacancy v, {bool forWhatsApp = true}) {
  final b = forWhatsApp ? '*' : '';
  final text = StringBuffer()
    ..writeln('$b${v.jobTitle}$b')
    ..writeln(v.institutionName);
  if (v.district.trim().isNotEmpty) {
    text.writeln(v.district.trim());
  }
  if (v.subjects.isNotEmpty) {
    text.writeln(v.subjects.join(', '));
  }
  final desc = v.description.trim();
  if (desc.isNotEmpty) {
    // Full job description (not a snippet) for teaching vacancies.
    text
      ..writeln()
      ..writeln(desc);
  }
  text
    ..writeln()
    ..writeln(_footer());
  return text.toString().trim();
}

String _shortDescription(String description) {
  const max = 280;
  final singleLine = description.replaceAll(RegExp(r'\s+'), ' ');
  if (singleLine.length <= max) return singleLine;
  return '${singleLine.substring(0, max).trim()}…';
}

/// The Afzal E Services contact footer appended to every share.
String _footer() =>
    '''*آن لائن ایپلائی اور مزید معلومات کے لئے رابطہ کریں*
*03161185662*
یا تشریف لائیں
*افضل ای سروسز*
*کوٹ دولت زئی بٹگرام نھر نزد نادرا گڑھی کپورہ مردان*
تازہ ترین اور بروقت معلومات
سکالرشپس ،نوکریوں کے اشتہارات
کے لئے وٹس ایپ گروپ جوائن کریں.

Jobs Group :
${AppConstants.whatsappJobsGroupUrl}

Whatsapp Channel :
${AppConstants.whatsappChannelUrl}''';
