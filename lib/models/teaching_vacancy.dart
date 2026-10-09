import 'package:cloud_firestore/cloud_firestore.dart';

/// Approval lifecycle for teaching-module records.
class TeachingApproval {
  const TeachingApproval._();

  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String suspended = 'suspended';

  static const Set<String> values = {
    pending,
    approved,
    rejected,
    suspended,
  };
}

/// A private teaching vacancy submitted by an organization and published
/// after admin approval.
///
/// Only vacancies with [approvalStatus] == 'approved' are visible to the
/// public. Field validation mirrors the Firestore security rules: corrupt
/// documents throw [FormatException] so the service layer can skip them.
class TeachingVacancy {
  const TeachingVacancy({
    required this.id,
    required this.organizationId,
    required this.ownerUid,
    required this.jobTitle,
    required this.institutionName,
    required this.district,
    this.city,
    this.subjects = const <String>[],
    this.gradeLevels = const <String>[],
    required this.qualification,
    this.experienceRequired,
    this.positionsCount = 1,
    this.salaryMin,
    this.salaryMax,
    this.employmentType,
    this.genderEligibility,
    required this.description,
    this.applicationDeadline,
    this.applicationMethod,
    this.applicationUrl,
    this.contactInstructions,
    required this.approvalStatus,
    this.rejectionReason,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String organizationId;
  final String ownerUid;
  final String jobTitle;

  /// Denormalized from the organization profile so vacancy cards render
  /// without an extra read (contact details stay in the org document).
  final String institutionName;
  final String district;
  final String? city;
  final List<String> subjects;
  final List<String> gradeLevels;
  final String qualification;
  final String? experienceRequired;
  final int positionsCount;
  final int? salaryMin;
  final int? salaryMax;
  final String? employmentType;
  final String? genderEligibility;
  final String description;
  final DateTime? applicationDeadline;
  final String? applicationMethod;
  final String? applicationUrl;
  final String? contactInstructions;
  final String approvalStatus;
  final String? rejectionReason;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Salary display, e.g. "Rs 30,000 – 45,000", or null when not provided.
  /// Never invented: null when the organization did not specify it.
  String? get salaryDisplay {
    if (salaryMin == null && salaryMax == null) return null;
    String fmt(int v) => v.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    if (salaryMin != null && salaryMax != null) {
      return 'Rs ${fmt(salaryMin!)} – ${fmt(salaryMax!)}';
    }
    final v = salaryMin ?? salaryMax!;
    return 'Rs ${fmt(v)}';
  }

  bool get isApproved => approvalStatus == TeachingApproval.approved;

  factory TeachingVacancy.fromJson(String id, Map<String, dynamic> json) {
    final jobTitle = _requiredString(json, 'jobTitle', id);
    final institutionName = _requiredString(json, 'institutionName', id);
    final district = _requiredString(json, 'district', id);
    final qualification = _requiredString(json, 'qualification', id);
    final description = _requiredString(json, 'description', id);
    final ownerUid = _requiredString(json, 'ownerUid', id);

    final rawStatus = json['approvalStatus'];
    final approvalStatus =
        rawStatus == null ? TeachingApproval.pending : rawStatus.toString();
    if (!TeachingApproval.values.contains(approvalStatus)) {
      throw FormatException(
        'TeachingVacancy "$id" has invalid approvalStatus "$approvalStatus".',
      );
    }

    return TeachingVacancy(
      id: id,
      organizationId: _optionalString(json, 'organizationId') ?? '',
      ownerUid: ownerUid,
      jobTitle: jobTitle,
      institutionName: institutionName,
      district: district,
      city: _optionalString(json, 'city'),
      subjects: _stringList(json['subjects']),
      gradeLevels: _stringList(json['gradeLevels']),
      qualification: qualification,
      experienceRequired: _optionalString(json, 'experienceRequired'),
      positionsCount: _optionalInt(json['positionsCount']) ?? 1,
      salaryMin: _optionalInt(json['salaryMin']),
      salaryMax: _optionalInt(json['salaryMax']),
      employmentType: _optionalString(json, 'employmentType'),
      genderEligibility: _optionalString(json, 'genderEligibility'),
      description: description,
      applicationDeadline:
          _parseDateTime(json['applicationDeadline'], 'applicationDeadline', id),
      applicationMethod: _optionalString(json, 'applicationMethod'),
      applicationUrl: _optionalString(json, 'applicationUrl'),
      contactInstructions: _optionalString(json, 'contactInstructions'),
      approvalStatus: approvalStatus,
      rejectionReason: _optionalString(json, 'rejectionReason'),
      publishedAt: _parseDateTime(json['publishedAt'], 'publishedAt', id),
      createdAt: _parseDateTime(json['createdAt'], 'createdAt', id),
      updatedAt: _parseDateTime(json['updatedAt'], 'updatedAt', id),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'ownerUid': ownerUid,
      'jobTitle': jobTitle,
      'institutionName': institutionName,
      'district': district,
      if (city != null) 'city': city,
      'subjects': subjects,
      'gradeLevels': gradeLevels,
      'qualification': qualification,
      if (experienceRequired != null) 'experienceRequired': experienceRequired,
      'positionsCount': positionsCount,
      if (salaryMin != null) 'salaryMin': salaryMin,
      if (salaryMax != null) 'salaryMax': salaryMax,
      if (employmentType != null) 'employmentType': employmentType,
      if (genderEligibility != null) 'genderEligibility': genderEligibility,
      'description': description,
      if (applicationDeadline != null)
        'applicationDeadline': Timestamp.fromDate(applicationDeadline!),
      if (applicationMethod != null) 'applicationMethod': applicationMethod,
      if (applicationUrl != null) 'applicationUrl': applicationUrl,
      if (contactInstructions != null)
        'contactInstructions': contactInstructions,
      'approvalStatus': approvalStatus,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (publishedAt != null) 'publishedAt': Timestamp.fromDate(publishedAt!),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  TeachingVacancy copyWith({String? approvalStatus, String? rejectionReason}) {
    return TeachingVacancy(
      id: id,
      organizationId: organizationId,
      ownerUid: ownerUid,
      jobTitle: jobTitle,
      institutionName: institutionName,
      district: district,
      city: city,
      subjects: subjects,
      gradeLevels: gradeLevels,
      qualification: qualification,
      experienceRequired: experienceRequired,
      positionsCount: positionsCount,
      salaryMin: salaryMin,
      salaryMax: salaryMax,
      employmentType: employmentType,
      genderEligibility: genderEligibility,
      description: description,
      applicationDeadline: applicationDeadline,
      applicationMethod: applicationMethod,
      applicationUrl: applicationUrl,
      contactInstructions: contactInstructions,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      publishedAt: publishedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key, String id) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('TeachingVacancy "$id" is missing "$key".');
  }
  return value.trim();
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  final trimmed = value.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const <String>[];
  return value
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

int? _optionalInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _parseDateTime(dynamic value, String key, String id) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  throw FormatException('TeachingVacancy "$id" has invalid "$key".');
}
