import 'package:flutter/material.dart';

/// Hand-rolled localization for Afzal E Services (English + Urdu).
///
/// A code-generated l10n setup was deliberately avoided so the strings
/// stay reviewable without a build step; every key falls back to English
/// when an Urdu translation is missing. Add new UI copy here — never
/// hard-code user-visible strings in widgets.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  bool get isUrdu => locale.languageCode == 'ur';

  static AppLocalizations of(BuildContext context) {
    final instance =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(instance != null, 'AppLocalizationsDelegate is not registered');
    return instance!;
  }

  String _t(String key) {
    if (isUrdu) {
      final urdu = _ur[key];
      if (urdu != null) return urdu;
    }
    return _en[key] ?? key;
  }

  // Navigation
  String get home => _t('home');
  String get saved => _t('saved');
  String get teaching => _t('teaching');

  // Home
  String get searchHint => _t('searchHint');
  String get latestAdvertisements => _t('latestAdvertisements');
  String get latest => _t('latest');
  String get closingSoon => _t('closingSoon');
  String get seeAll => _t('seeAll');
  String get listView => _t('listView');
  String get gridView => _t('gridView');
  String get noAdsFound => _t('noAdsFound');
  String get noAdsFoundHint => _t('noAdsFoundHint');
  String get browseAds => _t('browseAds');
  String get somethingWentWrong => _t('somethingWentWrong');
  String get retry => _t('retry');

  // Filters
  String get filter => _t('filter');
  String get applyFilters => _t('applyFilters');
  String get resetFilters => _t('resetFilters');
  String get reset => _t('reset');
  String get sortBy => _t('sortBy');
  String get relevance => _t('relevance');
  String get nearestDeadline => _t('nearestDeadline');
  String get category => _t('category');
  String get closingSoonOnly => _t('closingSoonOnly');
  String get closingSoonHint => _t('closingSoonHint');
  String get all => _t('all');

  // Categories
  String get jobs => _t('jobs');
  String get scholarships => _t('scholarships');
  String get admissions => _t('admissions');
  String get other => _t('other');

  // Details
  String get applyNow => _t('applyNow');
  String get officialSource => _t('officialSource');
  String get description => _t('description');
  String get deadline => _t('deadline');
  String get lastDate => _t('lastDate');
  String get location => _t('location');
  String get notSpecified => _t('notSpecified');
  String get officialInfoTitle => _t('officialInfoTitle');
  String get officialInfoBody => _t('officialInfoBody');
  String get linkOpenFailed => _t('linkOpenFailed');
  String get officialWebsite => _t('officialWebsite');

  // Deadline labels (localized equivalents of DeadlineInfo.label)
  String get lastDateNotSpecified => _t('lastDateNotSpecified');
  String get lastDateToday => _t('lastDateToday');
  String get closingTomorrow => _t('closingTomorrow');
  String get closingSoonLabel => _t('closingSoonLabel');
  String get newBadge => _t('newBadge');
  String get expired => _t('expired');
  String get today => _t('today');

  String daysLeft(int n) =>
      isUrdu ? '$n ${_t('daysLeftUnit')}' : '$n ${_t('daysLeftUnit')}';
  String dayLeft() => isUrdu ? '1 ${_t('dayLeftUnit')}' : '1 ${_t('dayLeftUnit')}';

  // Settings
  String get settings => _t('settings');
  String get appearance => _t('appearance');
  String get lightMode => _t('lightMode');
  String get darkMode => _t('darkMode');
  String get language => _t('language');
  String get english => _t('english');
  String get urdu => _t('urdu');
  String get systemDefault => _t('systemDefault');
  String get notifications => _t('notifications');
  String get notifNewAds => _t('notifNewAds');
  String get notifNewAdsDesc => _t('notifNewAdsDesc');
  String get notifClosingSoon => _t('notifClosingSoon');
  String get notifClosingSoonDesc => _t('notifClosingSoonDesc');
  String get notifTeaching => _t('notifTeaching');
  String get notifTeachingDesc => _t('notifTeachingDesc');
  String get notifPromotions => _t('notifPromotions');
  String get notifPromotionsDesc => _t('notifPromotionsDesc');
  String get about => _t('about');
  String get followWhatsappChannel => _t('followWhatsappChannel');
  String get version => _t('version');
  String get share => _t('share');

  // Teaching module (public)
  String get teachingTitle => _t('teachingTitle');
  String get teachingSubtitle => _t('teachingSubtitle');
  String get searchTeachingHint => _t('searchTeachingHint');
  String get district => _t('district');
  String get subject => _t('subject');
  String get qualification => _t('qualification');
  String get experience => _t('experience');
  String get noVacanciesFound => _t('noVacanciesFound');
  String get noVacanciesHint => _t('noVacanciesHint');
  String get subjectsRequired => _t('subjectsRequired');
  String get qualificationRequired => _t('qualificationRequired');
  String get experienceRequired => _t('experienceRequired');
  String get salaryRange => _t('salaryRange');
  String get employmentType => _t('employmentType');
  String get positions => _t('positions');
  String get jobDescription => _t('jobDescription');
  String get howToApply => _t('howToApply');
  String get contactInstructions => _t('contactInstructions');
  String get applicationDeadline => _t('applicationDeadline');
  String get postedOn => _t('postedOn');
  String get saveJob => _t('saveJob');
  String get savedJobs => _t('savedJobs');
  String get account => _t('account');

  // Auth (shared by organization / teacher flows)
  String get login => _t('login');
  String get register => _t('register');
  String get logout => _t('logout');
  String get email => _t('email');
  String get password => _t('password');
  String get fullName => _t('fullName');
  String get phone => _t('phone');
  String get city => _t('city');
  String get address => _t('address');
  String get requiredField => _t('requiredField');
  String get invalidEmail => _t('invalidEmail');
  String get passwordTooShort => _t('passwordTooShort');
  String get verifyEmailTitle => _t('verifyEmailTitle');
  String get verifyEmailBody => _t('verifyEmailBody');
  String get resendEmail => _t('resendEmail');
  String get forgotPassword => _t('forgotPassword');
  String get resetLinkSent => _t('resetLinkSent');

  // Generic actions
  String get ok => _t('ok');
  String get cancel => _t('cancel');
  String get save => _t('save');
  String get delete => _t('delete');
  String get edit => _t('edit');
  String get submit => _t('submit');
  String get approve => _t('approve');
  String get reject => _t('reject');
  String get confirmDelete => _t('confirmDelete');
  String get yes => _t('yes');
  String get no => _t('no');

  static const Map<String, String> _en = {
    'home': 'Home',
    'saved': 'Saved',
    'teaching': 'Teaching Jobs',
    'searchHint': 'Search advertisements…',
    'latestAdvertisements': 'Latest advertisements',
    'latest': 'Latest',
    'closingSoon': 'Closing soon',
    'seeAll': 'See all',
    'listView': 'List',
    'gridView': 'Grid',
    'noAdsFound': 'No advertisements found',
    'noAdsFoundHint': 'Try a different search or clear the filters.',
    'browseAds': 'Browse advertisements',
    'somethingWentWrong': 'Something went wrong',
    'retry': 'Retry',
    'filter': 'Filter',
    'applyFilters': 'Apply filters',
    'resetFilters': 'Reset filters',
    'reset': 'Reset',
    'sortBy': 'Sort by',
    'relevance': 'Relevance',
    'nearestDeadline': 'Nearest deadline',
    'category': 'Category',
    'closingSoonOnly': 'Closing soon only',
    'closingSoonHint': 'Only advertisements closing within 7 days',
    'all': 'All',
    'jobs': 'Jobs',
    'scholarships': 'Scholarships',
    'admissions': 'Admissions',
    'other': 'Other',
    'applyNow': 'Apply Now',
    'officialSource': 'Official Source',
    'description': 'Description',
    'deadline': 'Deadline',
    'lastDate': 'Last date',
    'location': 'Location',
    'notSpecified': 'Not specified',
    'officialInfoTitle': 'Official information',
    'officialInfoBody':
        'The links below come directly from the advertising organization.',
    'linkOpenFailed': 'Could not open the link.',
    'officialWebsite': 'Official website',
    'lastDateNotSpecified': 'LAST DATE NOT SPECIFIED',
    'lastDateToday': 'LAST DATE TODAY',
    'closingTomorrow': 'CLOSING TOMORROW',
    'closingSoonLabel': 'CLOSING SOON',
    'newBadge': 'NEW',
    'expired': 'EXPIRED',
    'today': 'Today',
    'daysLeftUnit': 'days left',
    'dayLeftUnit': 'day left',
    'settings': 'Settings',
    'appearance': 'Appearance',
    'lightMode': 'Light',
    'darkMode': 'Dark',
    'language': 'Language',
    'english': 'English',
    'urdu': 'Urdu',
    'systemDefault': 'System default',
    'notifications': 'Notifications',
    'notifNewAds': 'New advertisements',
    'notifNewAdsDesc': 'Notify me when new ads are published',
    'notifClosingSoon': 'Closing-soon reminders',
    'notifClosingSoonDesc': 'Remind me about saved ads closing in 1–2 days',
    'notifTeaching': 'Teaching vacancies',
    'notifTeachingDesc': 'Notify me about new teaching vacancies',
    'notifPromotions': 'Promotions',
    'notifPromotionsDesc': 'Occasional course and service promotions',
    'about': 'About',
    'followWhatsappChannel': 'Follow our WhatsApp Channel',
    'version': 'Version',
    'share': 'Share',
    'teachingTitle': 'Private Teaching Jobs',
    'teachingSubtitle': 'Verified vacancies from private schools & academies',
    'searchTeachingHint': 'Search teaching jobs…',
    'district': 'District',
    'subject': 'Subject',
    'qualification': 'Qualification',
    'experience': 'Experience',
    'noVacanciesFound': 'No vacancies found',
    'noVacanciesHint': 'Try a different search or clear the filters.',
    'subjectsRequired': 'Subjects required',
    'qualificationRequired': 'Qualification required',
    'experienceRequired': 'Experience required',
    'salaryRange': 'Salary range',
    'employmentType': 'Employment type',
    'positions': 'Positions',
    'jobDescription': 'Job description',
    'howToApply': 'How to apply',
    'contactInstructions': 'Contact instructions',
    'applicationDeadline': 'Application deadline',
    'postedOn': 'Posted on',
    'saveJob': 'Save job',
    'savedJobs': 'Saved jobs',
    'account': 'Account',
    'login': 'Log in',
    'register': 'Register',
    'logout': 'Log out',
    'email': 'Email',
    'password': 'Password',
    'fullName': 'Full name',
    'phone': 'Contact number',
    'city': 'City / locality',
    'address': 'Address',
    'requiredField': 'This field is required.',
    'invalidEmail': 'Please enter a valid email address.',
    'passwordTooShort': 'Password must be at least 6 characters.',
    'verifyEmailTitle': 'Verify your email',
    'verifyEmailBody':
        'We sent a verification link to your email. Verify it before continuing.',
    'resendEmail': 'Resend email',
    'forgotPassword': 'Forgot password?',
    'resetLinkSent': 'Password reset link sent. Check your inbox.',
    'ok': 'OK',
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'submit': 'Submit',
    'approve': 'Approve',
    'reject': 'Reject',
    'confirmDelete': 'Are you sure you want to delete this?',
    'yes': 'Yes',
    'no': 'No',
  };

  static const Map<String, String> _ur = {
    'home': 'ہوم',
    'saved': 'محفوظ شدہ',
    'teaching': 'تدریسی نوکریاں',
    'searchHint': 'اشتہارات تلاش کریں…',
    'latestAdvertisements': 'تازہ ترین اشتہارات',
    'latest': 'تازہ ترین',
    'closingSoon': 'جلد ختم ہونے والے',
    'seeAll': 'سب دیکھیں',
    'listView': 'فہرست',
    'gridView': 'گرڈ',
    'noAdsFound': 'کوئی اشتہار نہیں ملا',
    'noAdsFoundHint': 'کوئی اور تلاش آزمائیں یا فلٹر صاف کریں۔',
    'browseAds': 'اشتہارات دیکھیں',
    'somethingWentWrong': 'کچھ غلط ہو گیا',
    'retry': 'دوبارہ کوشش کریں',
    'filter': 'فلٹر',
    'applyFilters': 'فلٹر لگائیں',
    'resetFilters': 'فلٹر صاف کریں',
    'reset': 'صاف کریں',
    'sortBy': 'ترتیب',
    'relevance': 'مطابقت',
    'nearestDeadline': 'قریب ترین آخری تاریخ',
    'category': 'زمرہ',
    'closingSoonOnly': 'صرف جلد ختم ہونے والے',
    'closingSoonHint': 'صرف وہ اشتہارات جو 7 دن میں ختم ہو رہے ہیں',
    'all': 'سب',
    'jobs': 'نوکریاں',
    'scholarships': 'اسکالرشپس',
    'admissions': 'داخلے',
    'other': 'دیگر',
    'applyNow': 'ابھی اپلائی کریں',
    'officialSource': 'سرکاری ماخذ',
    'description': 'تفصیل',
    'deadline': 'آخری تاریخ',
    'lastDate': 'آخری تاریخ',
    'location': 'مقام',
    'notSpecified': 'درج نہیں',
    'officialInfoTitle': 'سرکاری معلومات',
    'officialInfoBody':
        'نیچے دیے گئے لنکس اشتہار دینے والے ادارے کی طرف سے ہیں۔',
    'linkOpenFailed': 'لنک نہیں کھولا جا سکا۔',
    'officialWebsite': 'سرکاری ویب سائٹ',
    'lastDateNotSpecified': 'آخری تاریخ درج نہیں',
    'lastDateToday': 'آج آخری تاریخ',
    'closingTomorrow': 'کل آخری تاریخ',
    'closingSoonLabel': 'جلد ختم ہو رہا ہے',
    'newBadge': 'نیا',
    'expired': 'میعاد ختم',
    'today': 'آج',
    'daysLeftUnit': 'دن باقی',
    'dayLeftUnit': 'دن باقی',
    'settings': 'ترتیبات',
    'appearance': 'ظاہری شکل',
    'lightMode': 'روشن',
    'darkMode': 'تاریک',
    'language': 'زبان',
    'english': 'English',
    'urdu': 'اردو',
    'systemDefault': 'سسٹم ڈیفالٹ',
    'notifications': 'اطلاعات',
    'notifNewAds': 'نئے اشتہارات',
    'notifNewAdsDesc': 'نئے اشتہارات شائع ہونے پر مطلع کریں',
    'notifClosingSoon': 'آخری تاریخ کی یاد دہانی',
    'notifClosingSoonDesc': '1–2 دن میں ختم ہونے والے محفوظ شدہ اشتہارات کی یاد دلائیں',
    'notifTeaching': 'تدریسی آسامیاں',
    'notifTeachingDesc': 'نئی تدریسی آسامیوں پر مطلع کریں',
    'notifPromotions': 'تشہیری پیغامات',
    'notifPromotionsDesc': 'کبھی کبھار کورسز اور سروسز کی تشہیر',
    'about': 'متعلق',
    'followWhatsappChannel': 'ہمارا واٹس ایپ چینل فالو کریں',
    'version': 'ورژن',
    'share': 'شیئر کریں',
    'teachingTitle': 'پرائیویٹ تدریسی نوکریاں',
    'teachingSubtitle': 'پرائیویٹ اسکولوں اور اکیڈمیز کی تصدیق شدہ آسامیاں',
    'searchTeachingHint': 'تدریسی نوکریاں تلاش کریں…',
    'district': 'ضلع',
    'subject': 'مضمون',
    'qualification': 'تعلیمی قابلیت',
    'experience': 'تجربہ',
    'noVacanciesFound': 'کوئی آسامی نہیں ملی',
    'noVacanciesHint': 'کوئی اور تلاش آزمائیں یا فلٹر صاف کریں۔',
    'subjectsRequired': 'مطلوبہ مضامین',
    'qualificationRequired': 'مطلوبہ قابلیت',
    'experienceRequired': 'مطلوبہ تجربہ',
    'salaryRange': 'تنخواہ',
    'employmentType': 'ملازمت کی نوعیت',
    'positions': 'آسامیاں',
    'jobDescription': 'ملازمت کی تفصیل',
    'howToApply': 'اپلائی کرنے کا طریقہ',
    'contactInstructions': 'رابطے کی ہدایات',
    'applicationDeadline': 'اپلائی کی آخری تاریخ',
    'postedOn': 'شائع ہونے کی تاریخ',
    'saveJob': 'نوکری محفوظ کریں',
    'savedJobs': 'محفوظ شدہ نوکریاں',
    'account': 'اکاؤنٹ',
    'login': 'لاگ اِن',
    'register': 'رجسٹر کریں',
    'logout': 'لاگ آؤٹ',
    'email': 'ای میل',
    'password': 'پاس ورڈ',
    'fullName': 'پورا نام',
    'phone': 'رابطہ نمبر',
    'city': 'شہر / علاقہ',
    'address': 'پتہ',
    'requiredField': 'یہ خانہ ضروری ہے۔',
    'invalidEmail': 'درست ای میل درج کریں۔',
    'passwordTooShort': 'پاس ورڈ کم از کم 6 حروف کا ہو۔',
    'verifyEmailTitle': 'ای میل کی تصدیق کریں',
    'verifyEmailBody':
        'آپ کے ای میل پر تصدیقی لنک بھیجا گیا ہے۔ جاری رکھنے سے پہلے تصدیق کریں۔',
    'resendEmail': 'ای میل دوبارہ بھیجیں',
    'forgotPassword': 'پاس ورڈ بھول گئے؟',
    'resetLinkSent': 'پاس ورڈ ری سیٹ لنک بھیج دیا گیا۔ ان باکس چیک کریں۔',
    'ok': 'ٹھیک ہے',
    'cancel': 'منسوخ کریں',
    'save': 'محفوظ کریں',
    'delete': 'حذف کریں',
    'edit': 'ترمیم کریں',
    'submit': 'جمع کرائیں',
    'approve': 'منظور کریں',
    'reject': 'مسترد کریں',
    'confirmDelete': 'کیا آپ واقعی حذف کرنا چاہتے ہیں؟',
    'yes': 'جی ہاں',
    'no': 'نہیں',
  };
}

/// Registers [AppLocalizations] with the widget tree. Material's own
/// localizations (for RTL + Material strings) come from
/// flutter_localizations delegates registered alongside this one.
class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'ur';

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
