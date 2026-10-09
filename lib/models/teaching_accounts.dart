import 'package:cloud_firestore/cloud_firestore.dart';

import 'teaching_vacancy.dart' show TeachingApproval;

/// An organization's account profile for the Private Teaching Jobs module.
///
/// Contact details are private: only the owning organization and the admin
/// can read this document. Public vacancy cards use the denormalized
/// institution name stored on the vacancy itself.
class TeachingOrganization {
  const TeachingOrganization({
    required this.id,
    required this.ownerUid,
    required this.institutionName,
    required this.institutionType,
    required this.contactPerson,
    required this.email,
    required this.district,
    this.city,
    this.address,
    this.contactNumber,
    required this.approvalStatus,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String institutionName;
  final String institutionType;
  final String contactPerson;
  final String email;
  final String district;
  final String? city;
  final String? address;
  final String? contactNumber;
  final String approvalStatus;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isApproved => approvalStatus == TeachingApproval.approved;
  bool get isPending => approvalStatus == TeachingApproval.pending;

  factory TeachingOrganization.fromJson(String id, Map<String, dynamic> json) {
    final ownerUid = _requiredString(json, 'ownerUid', id);
    final institutionName = _requiredString(json, 'institutionName', id);
    final institutionType =
        _optionalString(json, 'institutionType') ?? 'School';
    final contactPerson = _requiredString(json, 'contactPerson', id);
    final email = _requiredString(json, 'email', id);
    final district = _requiredString(json, 'district', id);

    final rawStatus = json['approvalStatus'];
    final approvalStatus =
        rawStatus == null ? TeachingApproval.pending : rawStatus.toString();
    if (!TeachingApproval.values.contains(approvalStatus)) {
      throw FormatException(
        'TeachingOrganization "$id" has invalid approvalStatus.',
      );
    }

    return TeachingOrganization(
      id: id,
      ownerUid: ownerUid,
      institutionName: institutionName,
      institutionType: institutionType,
      contactPerson: contactPerson,
      email: email,
      district: district,
      city: _optionalString(json, 'city'),
      address: _optionalString(json, 'address'),
      contactNumber: _optionalString(json, 'contactNumber'),
      approvalStatus: approvalStatus,
      rejectionReason: _optionalString(json, 'rejectionReason'),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'ownerUid': ownerUid,
      'institutionName': institutionName,
      'institutionType': institutionType,
      'contactPerson': contactPerson,
      'email': email,
      'district': district,
      if (city != null) 'city': city,
      if (address != null) 'address': address,
      if (contactNumber != null) 'contactNumber': contactNumber,
      'approvalStatus': approvalStatus,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}

/// A teacher's account profile. Private by default: only the owning
/// teacher and the admin can read it. The teacher may opt in to public
/// visibility, which takes effect only after admin approval.
class TeacherProfile {
  const TeacherProfile({
    required this.id,
    required this.ownerUid,
    required this.fullName,
    required this.email,
    required this.district,
    this.qualification,
    this.subjects = const <String>[],
    this.experienceYears,
    this.preferredEmploymentType,
    this.professionalSummary,
    this.cvStoragePath,
    this.profileVisibility = 'private',
    required this.approvalStatus,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String fullName;
  final String email;
  final String district;
  final String? qualification;
  final List<String> subjects;
  final int? experienceYears;
  final String? preferredEmploymentType;
  final String? professionalSummary;

  /// Private Storage path of the uploaded CV (never a public URL).
  /// CV upload requires the Blaze plan; null until then.
  final String? cvStoragePath;

  /// 'private' or 'public'. Public visibility needs admin approval.
  final String profileVisibility;
  final String approvalStatus;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isApproved => approvalStatus == TeachingApproval.approved;
  bool get hasCv => (cvStoragePath ?? '').isNotEmpty;

  factory TeacherProfile.fromJson(String id, Map<String, dynamic> json) {
    final ownerUid = _requiredString(json, 'ownerUid', id);
    final fullName = _requiredString(json, 'fullName', id);
    final email = _requiredString(json, 'email', id);
    final district = _requiredString(json, 'district', id);

    final rawStatus = json['approvalStatus'];
    final approvalStatus =
        rawStatus == null ? TeachingApproval.pending : rawStatus.toString();
    if (!TeachingApproval.values.contains(approvalStatus)) {
      throw FormatException(
        'TeacherProfile "$id" has invalid approvalStatus.',
      );
    }

    final visibility = _optionalString(json, 'profileVisibility') ?? 'private';
    if (visibility != 'private' && visibility != 'public') {
      throw FormatException(
        'TeacherProfile "$id" has invalid profileVisibility.',
      );
    }

    return TeacherProfile(
      id: id,
      ownerUid: ownerUid,
      fullName: fullName,
      email: email,
      district: district,
      qualification: _optionalString(json, 'qualification'),
      subjects: _stringList(json['subjects']),
      experienceYears: _optionalInt(json['experienceYears']),
      preferredEmploymentType:
          _optionalString(json, 'preferredEmploymentType'),
      professionalSummary: _optionalString(json, 'professionalSummary'),
      cvStoragePath: _optionalString(json, 'cvStoragePath'),
      profileVisibility: visibility,
      approvalStatus: approvalStatus,
      rejectionReason: _optionalString(json, 'rejectionReason'),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'ownerUid': ownerUid,
      'fullName': fullName,
      'email': email,
      'district': district,
      if (qualification != null) 'qualification': qualification,
      'subjects': subjects,
      if (experienceYears != null) 'experienceYears': experienceYears,
      if (preferredEmploymentType != null)
        'preferredEmploymentType': preferredEmploymentType,
      if (professionalSummary != null)
        'professionalSummary': professionalSummary,
      if (cvStoragePath != null) 'cvStoragePath': cvStoragePath,
      'profileVisibility': profileVisibility,
      'approvalStatus': approvalStatus,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}

String _requiredString(Map<String, dynamic> json, String key, String id) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Record "$id" is missing "$key".');
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

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}
