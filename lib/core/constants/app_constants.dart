/// Advertisement category with a stable id and a display label.
class AdCategory {
  const AdCategory(this.id, this.label);

  final String id;
  final String label;
}

/// App-wide constants: branding, categories, storage keys and contact info.
class AppConstants {
  const AppConstants._();

  // Branding
  static const String appName = 'Afzal E Services';
  static const String brandName = 'Afzal E Services';
  static const String tagline = 'Jobs • Scholarships • Admissions';

  // Contact
  static const String contactPhone = '03161185662';
  static const String contactCity = 'Mardan, Khyber Pakhtunkhwa';

  // Advertisement categories (v1.0). The admin system may manage these
  // server-side in a future update without an app release.
  static const List<AdCategory> categories = <AdCategory>[
    AdCategory('jobs', 'Jobs'),
    AdCategory('scholarships', 'Scholarships'),
    AdCategory('admissions', 'Admissions'),
    AdCategory('other', 'Other'),
  ];

  /// Pseudo-category id meaning "no category filter".
  static const String allCategoriesId = 'all';

  static bool isValidCategory(String id) {
    return categories.any((category) => category.id == id);
  }

  static String categoryLabel(String id) {
    for (final category in categories) {
      if (category.id == id) {
        return category.label;
      }
    }
    return 'Other';
  }

  // Advertisement lifecycle statuses.
  static const String statusDraft = 'draft';
  static const String statusPublished = 'published';
  static const String statusArchived = 'archived';

  static const Set<String> validStatuses = <String>{
    'draft',
    'published',
    'archived',
  };

  // Firestore collections.
  static const String advertisementsCollection = 'advertisements';
  static const String categoriesCollection = 'categories';

  // SharedPreferences keys.
  static const String themeModeKey = 'afzal_theme_mode';
  static const String bookmarksKey = 'afzal_bookmarks';
  static const String localeKey = 'afzal_locale';

  // Notification preference keys (all opt-in; promotions off by default).
  static const String notifNewAdsKey = 'afzal_notif_new_ads';
  static const String notifClosingSoonKey = 'afzal_notif_closing_soon';
  static const String notifTeachingKey = 'afzal_notif_teaching';
  static const String notifPromotionsKey = 'afzal_notif_promotions';

  // Notification bookkeeping keys.
  static const String notifLastCheckKey = 'afzal_notif_last_check';
  static const String notifSeenIdsKey = 'afzal_notif_seen_ids';
  static const String notifChannelId = 'afzal_opportunities';
  static const String teachingBookmarksKey = 'afzal_teaching_bookmarks';

  // Background task name for periodic vacancy/advertisement checks.
  static const String bgCheckTaskName = 'afzal-periodic-check';

  // External links.
  static const String whatsappChannelUrl =
      'https://whatsapp.com/channel/0029Va8EBlpLI8YRkHbALM1b';
  static const String whatsappJobsGroupUrl =
      'https://chat.whatsapp.com/J6AwEs4kl1P5aVEYHCTfPq';

  // Teaching module Firestore collections.
  static const String teachingOrganizationsCollection = 'teachingOrganizations';
  static const String teacherProfilesCollection = 'teacherProfiles';
  static const String teachingVacanciesCollection = 'teachingVacancies';
  static const String teachingApplicationsCollection = 'teachingApplications';

  /// KP districts prioritized by the teaching module (extensible).
  static const List<String> kpDistricts = <String>[
    'Mardan',
    'Peshawar',
    'Swabi',
    'Charsadda',
    'Nowshera',
    'Swat',
    'Buner',
    'Malakand',
    'Kohat',
    'Dera Ismail Khan',
    'Abbottabad',
    'Mansehra',
    'Haripur',
    'Bannu',
    'Lakki Marwat',
    'Tank',
    'Karak',
    'Hangu',
    'Upper Dir',
    'Lower Dir',
    'Chitral',
    'Shangla',
    'Battagram',
    'Torghar',
    'Kohistan',
  ];
}
