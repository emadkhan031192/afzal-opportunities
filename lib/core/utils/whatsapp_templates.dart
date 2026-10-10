import 'package:shared_preferences/shared_preferences.dart';

/// WhatsApp application message templates (3 versions × English/Urdu).
///
/// Placeholders [jobTitle], [schoolName] and [city] are replaced with the
/// actual vacancy data before sending. The applicant always reviews the
/// message and sends it manually — nothing is sent automatically.
class WhatsappTemplates {
  const WhatsappTemplates._();

  static const String _prefsVersionKey = 'wa_template_version';
  static const String _prefsLangKey = 'wa_template_lang_urdu';

  /// Template versions 1–3.
  static const List<({String en, String ur})> versions = [
    (
      en: 'Assalam-o-Alaikum,\n\nI am interested in applying for the position of [Job Title] at [School Name], [City]. Please share the application procedure and any further details.\n\nThank you.',
      ur: 'السلام علیکم!\n\nمیں [School Name]، [City] میں [Job Title] کی آسامی کے لیے درخواست دینا چاہتا/چاہتی ہوں۔ براہِ کرم درخواست دینے کا طریقہ اور مزید تفصیلات بتا دیں۔\n\nشکریہ۔',
    ),
    (
      en: 'Assalam-o-Alaikum,\n\nI saw your vacancy for [Job Title] at [School Name], [City]. Could you please tell me the required qualifications, experience, documents, and last date to apply?\n\nThank you.',
      ur: 'السلام علیکم!\n\nمیں نے [School Name]، [City] میں [Job Title] کی آسامی دیکھی ہے۔ براہِ کرم مطلوبہ تعلیمی قابلیت، تجربے، ضروری دستاویزات اور درخواست جمع کرانے کی آخری تاریخ کے بارے میں رہنمائی فرما دیں۔\n\nشکریہ۔',
    ),
    (
      en: 'Assalam-o-Alaikum,\n\nI would like to apply for [Job Title] at [School Name], [City]. Please let me know how I can submit my CV and supporting documents. I can share my details for your consideration.\n\nRegards.',
      ur: 'السلام علیکم!\n\nمیں [School Name]، [City] میں [Job Title] کے لیے درخواست دینا چاہتا/چاہتی ہوں۔ براہِ کرم بتا دیں کہ میں اپنا سی وی اور ضروری دستاویزات کیسے جمع کرا سکتا/سکتی ہوں۔ میں غور و خوض کے لیے اپنی تفصیلات فراہم کر سکتا/سکتی ہوں۔\n\nشکریہ۔',
    ),
  ];

  /// Fills placeholders with real vacancy data. Missing city falls back
  /// to the district so the message never shows a blank.
  static String fill({
    required int version,
    required bool urdu,
    required String jobTitle,
    required String schoolName,
    required String city,
  }) {
    final v = versions[version.clamp(0, versions.length - 1)];
    final template = urdu ? v.ur : v.en;
    return template
        .replaceAll('[Job Title]', jobTitle)
        .replaceAll('[School Name]', schoolName)
        .replaceAll('[City]', city);
  }

  static Future<({int version, bool urdu})> loadLastChoice() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      version: (prefs.getInt(_prefsVersionKey) ?? 0).clamp(0, 2),
      urdu: prefs.getBool(_prefsLangKey) ?? false,
    );
  }

  static Future<void> saveLastChoice({
    required int version,
    required bool urdu,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsVersionKey, version);
    await prefs.setBool(_prefsLangKey, urdu);
  }
}
