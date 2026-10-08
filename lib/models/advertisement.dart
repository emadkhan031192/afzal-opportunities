import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/deadline.dart';

/// An advertisement published by the Afzal E Services administrator.
class Advertisement {
  const Advertisement({
    required this.id,
    required this.title,
    required this.organization,
    required this.category,
    required this.description,
    required this.status,
    this.location,
    this.posterUrl,
    this.sourceUrl,
    this.applicationUrl,
    this.publishedAt,
    this.lastDate,
    this.isFeatured = false,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  final String id;
  final String title;
  final String organization;
  final String category;
  final String description;
  final String status;
  final String? location;
  final String? posterUrl;
  final String? sourceUrl;
  final String? applicationUrl;
  final DateTime? publishedAt;

  /// Date-only deadline. The advertisement stays active through 23:59:59
  /// PKT on this date.
  final DateTime? lastDate;
  final bool isFeatured;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  /// Builds an [Advertisement] from a Firestore document.
  ///
  /// Throws a [FormatException] when a required field is missing or invalid
  /// (title, organization, category, description, status, lastDate), so
  /// corrupt documents can be skipped by the service layer instead of
  /// crashing the feed.
  factory Advertisement.fromJson(String id, Map<String, dynamic> json) {
    final title = _requiredString(json, 'title', id);
    final organization = _requiredString(json, 'organization', id);
    final category = _requiredString(json, 'category', id);
    final description = _requiredString(json, 'description', id);

    if (!AppConstants.isValidCategory(category)) {
      throw FormatException(
        'Advertisement "$id" has invalid category "$category".',
      );
    }

    final rawStatus = json['status'];
    final status = rawStatus == null
        ? AppConstants.statusDraft
        : rawStatus.toString().trim();
    if (!AppConstants.validStatuses.contains(status)) {
      throw FormatException(
        'Advertisement "$id" has invalid status "$status".',
      );
    }

    return Advertisement(
      id: id,
      title: title,
      organization: organization,
      category: category,
      description: description,
      status: status,
      location: _optionalString(json, 'location'),
      posterUrl: _optionalString(json, 'posterUrl'),
      sourceUrl: _optionalString(json, 'sourceUrl'),
      applicationUrl: _optionalString(json, 'applicationUrl'),
      publishedAt: _parseDateTime(json['publishedAt'], 'publishedAt', id),
      lastDate: _parseLastDate(json['lastDate'], id),
      isFeatured: json['isFeatured'] == true,
      createdAt: _parseDateTime(json['createdAt'], 'createdAt', id),
      updatedAt: _parseDateTime(json['updatedAt'], 'updatedAt', id),
      createdBy: _optionalString(json, 'createdBy'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'organization': organization,
      'category': category,
      'description': description,
      'status': status,
      if (location != null) 'location': location,
      if (posterUrl != null) 'posterUrl': posterUrl,
      if (sourceUrl != null) 'sourceUrl': sourceUrl,
      if (applicationUrl != null) 'applicationUrl': applicationUrl,
      if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
      if (lastDate != null) 'lastDate': _dateString(lastDate!),
      'isFeatured': isFeatured,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (createdBy != null) 'createdBy': createdBy,
    };
  }

  /// Whether this advertisement should appear in the active feed:
  /// published and not past its last date (PKT).
  bool get isActive => isActiveAt(DateTime.now());

  /// [isActive] with an injectable clock for tests.
  bool isActiveAt(DateTime now) {
    if (status != AppConstants.statusPublished) {
      return false;
    }
    final info = getDeadlineInfo(
      lastDate: lastDate,
      publishedAt: publishedAt,
      now: now,
    );
    return !info.isExpired;
  }

  static String _requiredString(
    Map<String, dynamic> json,
    String key,
    String id,
  ) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException(
        'Advertisement "$id" is missing required field "$key".',
      );
    }
    return value.trim();
  }

  static String? _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('Advertisement field "$key" must be a string.');
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Parses a date-only deadline from a "YYYY-MM-DD" string, a Firestore
  /// [Timestamp] (date part only) or a [DateTime]. Null stays null.
  static DateTime? _parseLastDate(Object? value, String id) {
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      final date = value.toDate();
      return DateTime(date.year, date.month, date.day);
    }
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }
    if (value is String) {
      final text = value.trim();
      if (!_datePattern.hasMatch(text)) {
        throw FormatException(
          'Advertisement "$id" has malformed lastDate "$value". '
          'Expected "YYYY-MM-DD".',
        );
      }
      final parsed = DateTime.tryParse(text);
      // DateTime.tryParse normalizes out-of-range components (e.g. month 13
      // becomes January of the next year) instead of failing, so reject
      // anything that does not round-trip to the exact same calendar date.
      if (parsed == null || _dateString(parsed) != text) {
        throw FormatException(
          'Advertisement "$id" has malformed lastDate "$value". '
          'Expected a real calendar date as "YYYY-MM-DD".',
        );
      }
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
    throw FormatException(
      'Advertisement "$id" has unsupported lastDate value.',
    );
  }

  /// Parses an instant from a Firestore [Timestamp], ISO-8601 string or
  /// [DateTime]. Null (or blank string) stays null.
  static DateTime? _parseDateTime(Object? value, String key, String id) {
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) {
        return null;
      }
      final parsed = DateTime.tryParse(text);
      if (parsed == null) {
        throw FormatException(
          'Advertisement "$id" has malformed $key "$value".',
        );
      }
      return parsed;
    }
    throw FormatException('Advertisement "$id" has unsupported $key value.');
  }

  static String _dateString(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static final RegExp _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
}
