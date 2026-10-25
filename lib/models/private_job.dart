import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import 'teaching_vacancy.dart' show TeachingApproval;

/// A private-sector job posting.
///
/// Mirrors [TeachingVacancy]'s privacy design: the public document carries
/// only the apply-method enable flags; the actual phone/WhatsApp/email
/// details live in the private `privateJobContacts` collection (owner +
/// signed-in users only, enforced by Firestore rules).
///
/// Only jobs with [approvalStatus] == 'approved' AND [active] == true are
/// visible to the public. Field validation mirrors the Firestore security
/// rules: corrupt documents throw [FormatException] so the service layer
/// can skip them.
class PrivateJob {
  const PrivateJob({
    required this.id,
    required this.title,
    required this.company,
    required this.city,
    required this.description,
    this.salary,
    this.deadline,
    this.applyPhone,
    this.applyWhatsapp,
    this.applyEmail,
    this.enableCall = false,
    this.enableWhatsapp = false,
    this.enableEmail = false,
    required this.approvalStatus,
    this.rejectionReason,
    this.active = true,
    required this.postedBy,
    this.postedByType = 'company',
    this.organizationId,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String company;
  final String city;
  final String description;

  /// Free-text salary as entered by the poster (e.g. "Rs 50,000" or
  /// "As per market"). Null when not provided — never invented.
  final String? salary;
  final DateTime? deadline;
  final String? applyPhone;
  final String? applyWhatsapp;
  final String? applyEmail;
  final bool enableCall;
  final bool enableWhatsapp;
  final bool enableEmail;
  final String approvalStatus;
  final String? rejectionReason;

  /// Admin-controlled visibility switch. Approved jobs with active == false
  /// are hidden from the public feed (client-side filter; see
  /// PrivateJobService).
  final bool active;

  /// UID of the poster (organization owner, or the admin's UID).
  final String postedBy;

  /// 'admin' for admin-panel posts (live immediately), 'company' for
  /// organization posts (pending until admin approval).
  final String postedByType;

  /// Organization document id for company posts; null for admin posts.
  final String? organizationId;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isApproved => approvalStatus == TeachingApproval.approved;

  /// Publicly visible: approved AND active.
  bool get isPubliclyVisible => isApproved && active;

  bool get isPostedByAdmin => postedByType == 'admin';

  /// Phone is valid when it contains at least 7 digits.
  static bool isValidPhone(String? value) {
    if (value == null) return false;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 7;
  }

  /// Email is valid with a basic user@domain.tld shape.
  static bool isValidEmail(String? value) {
    if (value == null) return false;
    final v = value.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
  }

  bool get canCall => enableCall && isValidPhone(applyPhone);
  bool get canWhatsapp => enableWhatsapp && isValidPhone(applyWhatsapp);
  bool get canEmail => enableEmail && isValidEmail(applyEmail);

  /// At least one enabled channel with valid details. New jobs must
  /// satisfy this; the form and the rules enforce it.
  bool get hasValidApplyMethod => canCall || canWhatsapp || canEmail;

  /// WhatsApp number in international format for wa.me links:
  /// strips non-digits, converts leading 0 to Pakistan's 92.
  String? get whatsappInternational {
    if (!canWhatsapp) return null;
    var digits = applyWhatsapp!.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = '92${digits.substring(1)}';
    return digits;
  }

  factory PrivateJob.fromJson(String id, Map<String, dynamic> json) {
    final title = _requiredString(json, 'title', id);
    final company = _requiredString(json, 'company', id);
    final city = _requiredString(json, 'city', id);
    final description = _requiredString(json, 'description', id);
    final postedBy = _requiredString(json, 'postedBy', id);

    final rawStatus = json['approvalStatus'];
    final approvalStatus = rawStatus == null
        ? TeachingApproval.pending
        : rawStatus.toString();
    if (!TeachingApproval.values.contains(approvalStatus)) {
      throw FormatException(
        'PrivateJob "$id" has invalid approvalStatus "$approvalStatus".',
      );
    }

    final rawType = json['postedByType'];
    final postedByType = rawType == null ? 'company' : rawType.toString();
    if (postedByType != 'admin' && postedByType != 'company') {
      throw FormatException(
        'PrivateJob "$id" has invalid postedByType "$postedByType".',
      );
    }

    return PrivateJob(
      id: id,
      title: title,
      company: company,
      city: city,
      description: description,
      salary: _optionalString(json, 'salary'),
      deadline: _parseDateTime(json['deadline'], 'deadline', id),
      applyPhone: _optionalString(json, 'applyPhone'),
      applyWhatsapp: _optionalString(json, 'applyWhatsapp'),
      applyEmail: _optionalString(json, 'applyEmail'),
      enableCall: _optionalBool(json['enableCall']),
      enableWhatsapp: _optionalBool(json['enableWhatsapp']),
      enableEmail: _optionalBool(json['enableEmail']),
      approvalStatus: approvalStatus,
      rejectionReason: _optionalString(json, 'rejectionReason'),
      active: _optionalBool(json['active'], defaultValue: true),
      postedBy: postedBy,
      postedByType: postedByType,
      organizationId: _optionalString(json, 'organizationId'),
      publishedAt: _parseDateTime(json['publishedAt'], 'publishedAt', id),
      createdAt: _parseDateTime(json['createdAt'], 'createdAt', id),
      updatedAt: _parseDateTime(json['updatedAt'], 'updatedAt', id),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'company': company,
      'city': city,
      'description': description,
      if (salary != null) 'salary': salary,
      if (deadline != null) 'deadline': Timestamp.fromDate(deadline!),
      // NOTE: applyPhone/applyWhatsapp/applyEmail are NEVER written to the
      // public job document. They live in the private privateJobContacts
      // collection (owner + signed-in users only). Only the enable flags
      // are public.
      'enableCall': enableCall,
      'enableWhatsapp': enableWhatsapp,
      'enableEmail': enableEmail,
      'approvalStatus': approvalStatus,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'active': active,
      'postedBy': postedBy,
      'postedByType': postedByType,
      if (organizationId != null) 'organizationId': organizationId,
      if (publishedAt != null) 'publishedAt': Timestamp.fromDate(publishedAt!),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  /// Returns a copy with private contact details merged in (fetched from
  /// the privateJobContacts collection for signed-in users).
  PrivateJob withContact(PrivateJobContact contact) {
    return PrivateJob(
      id: id,
      title: title,
      company: company,
      city: city,
      description: description,
      salary: salary,
      deadline: deadline,
      applyPhone: contact.applyPhone,
      applyWhatsapp: contact.applyWhatsapp,
      applyEmail: contact.applyEmail,
      enableCall: enableCall,
      enableWhatsapp: enableWhatsapp,
      enableEmail: enableEmail,
      approvalStatus: approvalStatus,
      rejectionReason: rejectionReason,
      active: active,
      postedBy: postedBy,
      postedByType: postedByType,
      organizationId: organizationId,
      publishedAt: publishedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Private contact details for a private job, stored in the
/// `privateJobContacts` collection (not in the public job doc).
///
/// Read: owner, admin, or any signed-in user. Write: owner or admin.
/// Guests (not signed in) cannot read these via Firebase rules.
class PrivateJobContact {
  const PrivateJobContact({
    this.applyPhone,
    this.applyWhatsapp,
    this.applyEmail,
  });

  final String? applyPhone;
  final String? applyWhatsapp;
  final String? applyEmail;

  factory PrivateJobContact.fromJson(Map<String, dynamic> json) {
    String? opt(String key) {
      final v = json[key];
      if (v is! String) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    return PrivateJobContact(
      applyPhone: opt('applyPhone'),
      applyWhatsapp: opt('applyWhatsapp'),
      applyEmail: opt('applyEmail'),
    );
  }

  Map<String, dynamic> toJson(String postedBy) {
    return {
      'postedBy': postedBy,
      if (applyPhone != null) 'applyPhone': applyPhone,
      if (applyWhatsapp != null) 'applyWhatsapp': applyWhatsapp,
      if (applyEmail != null) 'applyEmail': applyEmail,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  bool get isEmpty =>
      applyPhone == null && applyWhatsapp == null && applyEmail == null;
}

/// Pure city-filter helper, shared by the feed screen and unit tests.
///
/// [city] is '' (or 'all') for no filtering; otherwise only jobs whose
/// city matches exactly are kept.
List<PrivateJob> filterPrivateJobsByCity(List<PrivateJob> jobs, String city) {
  final c = city.trim();
  if (c.isEmpty || c.toLowerCase() == 'all') return List.of(jobs);
  return jobs.where((j) => j.city == c).toList();
}

/// Whether [city] is one of the offered filter cities.
bool isValidJobCity(String city) => AppConstants.kpkJobCities.contains(city);

String _requiredString(Map<String, dynamic> json, String key, String id) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('PrivateJob "$id" is missing "$key".');
  }
  return value.trim();
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  final trimmed = value.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}

bool _optionalBool(dynamic value, {bool defaultValue = false}) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return defaultValue;
}

DateTime? _parseDateTime(dynamic value, String key, String id) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  throw FormatException('PrivateJob "$id" has invalid "$key".');
}
