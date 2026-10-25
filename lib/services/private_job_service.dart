import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/deadline.dart' show pktNow;
import '../models/private_job.dart';
import '../models/teaching_vacancy.dart' show TeachingApproval;
import 'firebase_config.dart';

/// Reads and writes Private Jobs module records.
///
/// Mirrors [TeachingService]'s patterns: the public feed is limited to
/// approved jobs (enforced again by the security rules), the active flag
/// and expiry are filtered client-side so no composite Firestore indexes
/// are required, and contact details live in the private
/// `privateJobContacts` collection — never in the public job document.
///
/// Approval flow: company posts are created with approvalStatus ==
/// 'pending' and only an admin can approve them. Admin-panel posts are
/// created as 'approved' directly (the admin panel signs in as an admin,
/// so the rules allow it). Owners can never escalate their own status.
class PrivateJobService {
  PrivateJobService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  bool get _ready => FirebaseConfig.isConfigured;

  // ------------------------------------------------------------------
  // Public job feed
  // ------------------------------------------------------------------

  /// Live stream of approved jobs, newest first. The active flag is
  /// filtered client-side ([applyPublicFilter]) so the query needs no
  /// composite index.
  Stream<List<PrivateJob>> watchApprovedJobs() {
    if (!_ready) return Stream<List<PrivateJob>>.value(const []);
    return _db
        .collection(AppConstants.privateJobsCollection)
        .where('approvalStatus', isEqualTo: TeachingApproval.approved)
        .snapshots()
        .map(_parseJobs)
        .map(_newestFirst);
  }

  /// One-shot fetch of approved jobs (used by background checks).
  Future<List<PrivateJob>> fetchApprovedJobs() async {
    if (!_ready) return const [];
    final snapshot = await _db
        .collection(AppConstants.privateJobsCollection)
        .where('approvalStatus', isEqualTo: TeachingApproval.approved)
        .get();
    return _newestFirst(_parseJobs(snapshot));
  }

  /// Fetches a single job; returns null when missing, invalid, or not
  /// publicly visible (the rules deny non-approved reads for the public).
  Future<PrivateJob?> getJob(String id) async {
    if (!_ready) return null;
    try {
      final doc = await _db
          .collection(AppConstants.privateJobsCollection)
          .doc(id)
          .get();
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      final job = PrivateJob.fromJson(doc.id, data);
      return job.isPubliclyVisible ? job : null;
    } catch (e) {
      debugPrint('getJob($id) failed: $e');
      return null;
    }
  }

  /// Public-feed filter: keeps approved + active jobs, hides expired ones
  /// by default, and applies the city filter ('' means all cities).
  static List<PrivateJob> applyPublicFilter(
    List<PrivateJob> jobs, {
    String city = '',
    bool hideExpired = true,
    DateTime? now,
  }) {
    return jobs.where((j) {
      if (!j.isPubliclyVisible) return false;
      if (hideExpired && isExpired(j, now: now)) return false;
      if (city.trim().isNotEmpty && j.city != city.trim()) return false;
      return true;
    }).toList();
  }

  /// Whether the job's deadline has passed (PKT day).
  static bool isExpired(PrivateJob job, {DateTime? now}) {
    final deadline = job.deadline;
    if (deadline == null) return false;
    final pkt = pktNow(now);
    final today = DateTime(pkt.year, pkt.month, pkt.day);
    final target = DateTime(deadline.year, deadline.month, deadline.day);
    return target.isBefore(today);
  }

  List<PrivateJob> _parseJobs(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final out = <PrivateJob>[];
    for (final doc in snapshot.docs) {
      try {
        out.add(PrivateJob.fromJson(doc.id, doc.data()));
      } on FormatException catch (e) {
        debugPrint('Skipping invalid private job ${doc.id}: $e');
      }
    }
    return out;
  }

  List<PrivateJob> _newestFirst(List<PrivateJob> jobs) {
    jobs.sort((a, b) {
      final pa = a.publishedAt ?? a.createdAt;
      final pb = b.publishedAt ?? b.createdAt;
      if (pa == null && pb == null) return 0;
      if (pa == null) return 1;
      if (pb == null) return -1;
      return pb.compareTo(pa);
    });
    return jobs;
  }

  // ------------------------------------------------------------------
  // Company records (owner-scoped)
  // ------------------------------------------------------------------

  /// The poster's own private jobs across all statuses.
  Stream<List<PrivateJob>> watchMyJobs(String uid) {
    if (!_ready) return Stream<List<PrivateJob>>.value(const []);
    return _db
        .collection(AppConstants.privateJobsCollection)
        .where('postedBy', isEqualTo: uid)
        .snapshots()
        .map(_parseJobs)
        .map(_newestFirst);
  }

  /// Submits a new job as 'pending'. Never auto-publishes.
  /// Contact details are written to the private privateJobContacts
  /// collection (never to the public job document).
  Future<String> submitJob(PrivateJob job) async {
    final data = job.toJson()
      ..['approvalStatus'] = TeachingApproval.pending
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    data.remove('publishedAt');
    data.remove('rejectionReason');
    final ref = await _db
        .collection(AppConstants.privateJobsCollection)
        .add(data);
    await _writeJobContact(ref.id, job);
    return ref.id;
  }

  /// Writes the private contact details for a job. Deletes the contact
  /// doc when no details remain.
  Future<void> _writeJobContact(String jobId, PrivateJob job) async {
    final contact = PrivateJobContact(
      applyPhone: job.applyPhone,
      applyWhatsapp: job.applyWhatsapp,
      applyEmail: job.applyEmail,
    );
    final ref = _db
        .collection(AppConstants.privateJobContactsCollection)
        .doc(jobId);
    if (contact.isEmpty) {
      await ref.delete().catchError((_) {});
    } else {
      await ref.set(contact.toJson(job.postedBy));
    }
  }

  /// Fetches the private contact details for a job.
  /// Returns null for guests (Firestore rules deny unauthenticated reads)
  /// or when no contact details were saved.
  Future<PrivateJobContact?> getJobContact(String jobId) async {
    try {
      final doc = await _db
          .collection(AppConstants.privateJobContactsCollection)
          .doc(jobId)
          .get();
      if (!doc.exists) return null;
      return PrivateJobContact.fromJson(doc.data() ?? {});
    } catch (_) {
      return null;
    }
  }

  /// Updates the poster's own job. Material changes to an approved job
  /// send it back to 'pending' for admin re-approval.
  Future<void> updateJob(PrivateJob job) async {
    final data = job.toJson()..['updatedAt'] = FieldValue.serverTimestamp();
    // toJson omits null optionals; explicitly delete them so clearing a
    // field in the edit form actually removes it from Firestore.
    if (job.salary == null) data['salary'] = FieldValue.delete();
    if (job.deadline == null) data['deadline'] = FieldValue.delete();
    if (job.isApproved) {
      // Material change to a live job: re-approval required.
      data['approvalStatus'] = TeachingApproval.pending;
      data.remove('publishedAt');
    } else {
      // Never let the client escalate its own status.
      data.remove('approvalStatus');
    }
    data.remove('rejectionReason');
    await _db
        .collection(AppConstants.privateJobsCollection)
        .doc(job.id)
        .update(data);
    await _writeJobContact(job.id, job);
  }

  /// Deletes the poster's own job (rules enforce ownership).
  /// Also removes the private contact details.
  Future<void> deleteJob(String id) async {
    await _db.collection(AppConstants.privateJobsCollection).doc(id).delete();
    await _db
        .collection(AppConstants.privateJobContactsCollection)
        .doc(id)
        .delete()
        .catchError((_) {});
  }

  /// Deletes all private jobs posted by [uid] plus their private contact
  /// docs. Used by the in-app "Delete account" flow.
  Future<void> deleteJobsForUser(String uid, {WriteBatch? batch}) async {
    if (!_ready) return;
    final snap = await _db
        .collection(AppConstants.privateJobsCollection)
        .where('postedBy', isEqualTo: uid)
        .get();
    final b = batch ?? _db.batch();
    for (final doc in snap.docs) {
      b.delete(doc.reference);
      b.delete(
        _db.collection(AppConstants.privateJobContactsCollection).doc(doc.id),
      );
    }
    if (batch == null) await b.commit();
  }
}
