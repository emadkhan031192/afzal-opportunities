import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/deadline.dart' show pktNow;
import '../models/teaching_accounts.dart';
import '../models/teaching_vacancy.dart';
import 'firebase_config.dart';

/// Filters for the public teaching-vacancy feed. All optional; filtering
/// beyond the approval status happens client-side so no composite
/// Firestore indexes are required.
///
/// Experience bands: '' (any), 'fresh' (entry level — no experience
/// required or unspecified), 'experienced' (explicitly requires
/// experience). Vacancies that do not specify experience are never
/// hidden by the experience filter.
class VacancyFilter {
  const VacancyFilter({
    this.query = '',
    this.district = '',
    this.subject = '',
    this.qualification = '',
    this.experience = '',
    this.hideExpired = true,
  });

  final String query;
  final String district;
  final String subject;
  final String qualification;
  final String experience;
  final bool hideExpired;

  bool get isActive =>
      query.trim().isNotEmpty ||
      district.isNotEmpty ||
      subject.isNotEmpty ||
      qualification.isNotEmpty ||
      experience.isNotEmpty;
}

/// Reads and writes teaching-module records.
///
/// Public reads are limited to approved vacancies (enforced again by the
/// security rules). Organizations and teachers can only touch their own
/// records, and neither can self-approve — the rules reject any write
/// that sets approvalStatus to 'approved' from a non-admin.
class TeachingService {
  TeachingService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  bool get _ready => FirebaseConfig.isConfigured;

  // ------------------------------------------------------------------
  // Public vacancy feed
  // ------------------------------------------------------------------

  /// Live stream of approved vacancies, newest first.
  Stream<List<TeachingVacancy>> watchApprovedVacancies() {
    if (!_ready) return Stream<List<TeachingVacancy>>.value(const []);
    return _db
        .collection(AppConstants.teachingVacanciesCollection)
        .where('approvalStatus', isEqualTo: TeachingApproval.approved)
        .snapshots()
        .map(_parseVacancies)
        .map(_newestFirst);
  }

  /// One-shot fetch of approved vacancies (used by background checks).
  Future<List<TeachingVacancy>> fetchApprovedVacancies() async {
    if (!_ready) return const [];
    final snapshot = await _db
        .collection(AppConstants.teachingVacanciesCollection)
        .where('approvalStatus', isEqualTo: TeachingApproval.approved)
        .get();
    return _newestFirst(_parseVacancies(snapshot));
  }

  /// Fetches a single vacancy; returns null when missing, invalid, or
  /// not approved (the rules deny non-approved reads for the public).
  Future<TeachingVacancy?> getVacancy(String id) async {
    if (!_ready) return null;
    try {
      final doc = await _db
          .collection(AppConstants.teachingVacanciesCollection)
          .doc(id)
          .get();
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      final vacancy = TeachingVacancy.fromJson(doc.id, data);
      return vacancy.isApproved ? vacancy : null;
    } catch (e) {
      debugPrint('getVacancy($id) failed: $e');
      return null;
    }
  }

  /// Applies search text and facet filters client-side. Expired
  /// vacancies are hidden by default.
  static List<TeachingVacancy> applyFilter(
    List<TeachingVacancy> vacancies,
    VacancyFilter filter, {
    DateTime? now,
  }) {
    final query = filter.query.trim().toLowerCase();
    return vacancies.where((v) {
      if (filter.hideExpired && isExpired(v, now: now)) return false;
      if (filter.district.isNotEmpty && v.district != filter.district) {
        return false;
      }
      if (filter.subject.isNotEmpty &&
          !v.subjects.any(
            (s) => s.toLowerCase() == filter.subject.toLowerCase(),
          )) {
        return false;
      }
      if (filter.qualification.isNotEmpty &&
          !v.qualification.toLowerCase().contains(
            filter.qualification.toLowerCase(),
          )) {
        return false;
      }
      if (filter.experience.isNotEmpty) {
        final requiresExperience = _requiresExperience(v.experienceRequired);
        if (filter.experience == 'fresh' && requiresExperience) return false;
        if (filter.experience == 'experienced' && !requiresExperience) {
          return false;
        }
      }
      if (query.isNotEmpty) {
        final haystack =
            '${v.jobTitle} ${v.institutionName} ${v.district} ${v.subjects.join(' ')}'
                .toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      return true;
    }).toList();
  }

  /// Whether the vacancy's application deadline has passed (PKT day).
  static bool isExpired(TeachingVacancy vacancy, {DateTime? now}) {
    final deadline = vacancy.applicationDeadline;
    if (deadline == null) return false;
    final pkt = pktNow(now);
    final today = DateTime(pkt.year, pkt.month, pkt.day);
    final target = DateTime(deadline.year, deadline.month, deadline.day);
    return target.isBefore(today);
  }

  /// Whether the vacancy explicitly requires teaching experience.
  /// Empty/unspecified (or explicit "fresh"/"no experience") counts as
  /// entry-level — never treated as requiring experience.
  static bool _requiresExperience(String? experienceRequired) {
    final text = (experienceRequired ?? '').trim().toLowerCase();
    if (text.isEmpty) return false;
    if (RegExp(
      r'fresh|no experience|not required|entry.level',
    ).hasMatch(text)) {
      return false;
    }
    // Any mention of years (e.g. "2 years") means experience is required.
    return RegExp(r'\d+\s*(year|yr)').hasMatch(text);
  }

  List<TeachingVacancy> _parseVacancies(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final out = <TeachingVacancy>[];
    for (final doc in snapshot.docs) {
      try {
        out.add(TeachingVacancy.fromJson(doc.id, doc.data()));
      } on FormatException catch (e) {
        debugPrint('Skipping invalid vacancy ${doc.id}: $e');
      }
    }
    return out;
  }

  List<TeachingVacancy> _newestFirst(List<TeachingVacancy> vacancies) {
    vacancies.sort((a, b) {
      final pa = a.publishedAt ?? a.createdAt;
      final pb = b.publishedAt ?? b.createdAt;
      if (pa == null && pb == null) return 0;
      if (pa == null) return 1;
      if (pb == null) return -1;
      return pb.compareTo(pa);
    });
    return vacancies;
  }

  // ------------------------------------------------------------------
  // Organization records (owner-scoped)
  // ------------------------------------------------------------------

  Future<TeachingOrganization?> getMyOrganization(String uid) async {
    if (!_ready) return null;
    final snapshot = await _db
        .collection(AppConstants.teachingOrganizationsCollection)
        .where('ownerUid', isEqualTo: uid)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    try {
      final doc = snapshot.docs.first;
      return TeachingOrganization.fromJson(doc.id, doc.data());
    } on FormatException catch (e) {
      debugPrint('Skipping invalid organization: $e');
      return null;
    }
  }

  /// Creates or updates the caller's organization profile. The approval
  /// status is always forced to 'pending' on write — organizations can
  /// never approve themselves (rules enforce this too).
  Future<String> saveOrganization(TeachingOrganization org) async {
    final data = org.toJson()
      ..['approvalStatus'] = TeachingApproval.pending
      ..['updatedAt'] = FieldValue.serverTimestamp();
    data.remove('rejectionReason');
    if (org.id.isEmpty) {
      data['createdAt'] = FieldValue.serverTimestamp();
      final ref = await _db
          .collection(AppConstants.teachingOrganizationsCollection)
          .add(data);
      return ref.id;
    }
    await _db
        .collection(AppConstants.teachingOrganizationsCollection)
        .doc(org.id)
        .set(data, SetOptions(merge: true));
    return org.id;
  }

  /// The organization's own vacancies across all statuses.
  Stream<List<TeachingVacancy>> watchMyVacancies(String uid) {
    if (!_ready) return Stream<List<TeachingVacancy>>.value(const []);
    return _db
        .collection(AppConstants.teachingVacanciesCollection)
        .where('ownerUid', isEqualTo: uid)
        .snapshots()
        .map(_parseVacancies)
        .map(_newestFirst);
  }

  /// Submits a new vacancy as 'pending'. Never auto-publishes.
  Future<String> submitVacancy(TeachingVacancy vacancy) async {
    final data = vacancy.toJson()
      ..['approvalStatus'] = TeachingApproval.pending
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    data.remove('publishedAt');
    data.remove('rejectionReason');
    final ref = await _db
        .collection(AppConstants.teachingVacanciesCollection)
        .add(data);
    return ref.id;
  }

  /// Updates the caller's own vacancy. Material changes to an approved
  /// vacancy send it back to 'pending' for admin re-approval.
  Future<void> updateVacancy(TeachingVacancy vacancy) async {
    final data = vacancy.toJson()..['updatedAt'] = FieldValue.serverTimestamp();
    if (vacancy.isApproved) {
      // Material change to a live vacancy: re-approval required.
      data['approvalStatus'] = TeachingApproval.pending;
      data.remove('publishedAt');
    } else {
      // Never let the client escalate its own status.
      data.remove('approvalStatus');
    }
    data.remove('rejectionReason');
    await _db
        .collection(AppConstants.teachingVacanciesCollection)
        .doc(vacancy.id)
        .update(data);
  }

  /// Deletes the caller's own vacancy (rules enforce ownership).
  Future<void> deleteVacancy(String id) async {
    await _db
        .collection(AppConstants.teachingVacanciesCollection)
        .doc(id)
        .delete();
  }

  // ------------------------------------------------------------------
  // Teacher records (owner-scoped)
  // ------------------------------------------------------------------

  Future<TeacherProfile?> getMyProfile(String uid) async {
    if (!_ready) return null;
    final snapshot = await _db
        .collection(AppConstants.teacherProfilesCollection)
        .where('ownerUid', isEqualTo: uid)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    try {
      final doc = snapshot.docs.first;
      return TeacherProfile.fromJson(doc.id, doc.data());
    } on FormatException catch (e) {
      debugPrint('Skipping invalid teacher profile: $e');
      return null;
    }
  }

  /// Creates or updates the caller's teacher profile. Approval status
  /// can never be escalated by the client.
  Future<String> saveProfile(TeacherProfile profile) async {
    final data = profile.toJson()..['updatedAt'] = FieldValue.serverTimestamp();
    data.remove('approvalStatus');
    data.remove('rejectionReason');
    if (profile.id.isEmpty) {
      data['approvalStatus'] = TeachingApproval.pending;
      data['createdAt'] = FieldValue.serverTimestamp();
      final ref = await _db
          .collection(AppConstants.teacherProfilesCollection)
          .add(data);
      return ref.id;
    }
    await _db
        .collection(AppConstants.teacherProfilesCollection)
        .doc(profile.id)
        .set(data, SetOptions(merge: true));
    return profile.id;
  }
}
