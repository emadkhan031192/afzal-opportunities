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
  static const String appName = 'Afzal Opportunities';
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
}
