import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../models/teaching_accounts.dart';
import '../../../models/teaching_vacancy.dart';
import '../../../services/bookmark_service.dart';
import '../../../services/teaching_auth.dart';
import '../../../services/teaching_service.dart';
import '../../../widgets/state_views.dart';
import '../../../widgets/teaching_vacancy_card.dart';
import '../auth/verify_email_screen.dart';
import '../teacher_profile_form_screen.dart';
import '../vacancy_details_screen.dart';

/// Teacher dashboard: profile status, profile editing, CV upload status,
/// saved teaching jobs, and quick browsing.
class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({
    super.key,
    required this.auth,
    required this.service,
  });

  final TeachingAuth auth;
  final TeachingService service;

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  late final BookmarkService _savedJobs =
      BookmarkService(storageKey: AppConstants.teachingBookmarksKey);

  @override
  void initState() {
    super.initState();
    _savedJobs.load();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final uid = widget.auth.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.myProfile),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: s.logout,
            onPressed: () async {
              await widget.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((r) => r.isFirst);
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<TeacherProfile?>(
        future: widget.service.getMyProfile(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final profile = snapshot.data;
          if (profile == null) {
            return ErrorView(
              message: s.somethingWentWrong,
              onRetry: () => setState(() {}),
            );
          }
          return _Body(
            auth: widget.auth,
            service: widget.service,
            profile: profile,
            savedJobs: _savedJobs,
            onChanged: () => setState(() {}),
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.auth,
    required this.service,
    required this.profile,
    required this.savedJobs,
    required this.onChanged,
  });

  final TeachingAuth auth;
  final TeachingService service;
  final TeacherProfile profile;
  final BookmarkService savedJobs;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: () async => onChanged(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          if (!auth.isEmailVerified)
            _VerifyBanner(onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
              );
            }),
          _StatusCard(profile: profile),
          const SizedBox(height: 12),
          _ProfileCard(profile: profile),
          const SizedBox(height: 12),
          _CvCard(profile: profile),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) =>
                        TeacherProfileFormScreen(existing: profile),
                  ),
                );
                if (changed == true) onChanged();
              },
              icon: const Icon(Icons.edit_outlined),
              label: Text(s.edit),
            ),
          ),
          const SizedBox(height: 20),
          Text(s.savedJobs, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _SavedJobsList(savedJobs: savedJobs, service: service),
        ],
      ),
    );
  }
}

class _VerifyBanner extends StatelessWidget {
  const _VerifyBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.mark_email_unread_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.verificationRequired,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  s.verificationRequiredDesc,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(onPressed: onTap, child: Text(s.verifyEmailTitle)),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.profile});

  final TeacherProfile profile;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    String statusText;
    Color color;
    String? desc;
    switch (profile.approvalStatus) {
      case TeachingApproval.approved:
        statusText = s.statusApproved;
        color = Colors.green.shade700;
        break;
      case TeachingApproval.rejected:
        statusText = s.statusRejected;
        color = theme.colorScheme.error;
        desc = profile.rejectionReason != null
            ? '${s.rejectedDesc} ${profile.rejectionReason}'
            : null;
        break;
      case TeachingApproval.suspended:
        statusText = s.statusSuspended;
        color = theme.colorScheme.error;
        desc = s.suspendedDesc;
        break;
      case TeachingApproval.pending:
      default:
        statusText = s.statusPending;
        color = Colors.orange.shade800;
        desc = s.pendingReviewDesc;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    profile.fullName,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            if (desc != null) ...[
              const SizedBox(height: 8),
              Text(desc, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final TeacherProfile profile;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rows = <String, String>{
      s.email: profile.email,
      s.district: profile.district,
      if ((profile.qualification ?? '').isNotEmpty)
        s.qualification: profile.qualification!,
      if (profile.subjects.isNotEmpty)
        s.subject: profile.subjects.join(', '),
      if (profile.experienceYears != null)
        s.experience: '${profile.experienceYears}',
      if ((profile.preferredEmploymentType ?? '').isNotEmpty)
        s.preferredEmploymentType: profile.preferredEmploymentType!,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in rows.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 150,
                      child: Text(
                        entry.key,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if ((profile.professionalSummary ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                s.professionalSummary,
                style: theme.textTheme.bodySmall,
              ),
              Text(
                profile.professionalSummary!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// CV upload card. Uploads are blocked until the Blaze plan is enabled;
/// the UI is ready and the blocker is explained honestly.
class _CvCard extends StatelessWidget {
  const _CvCard({required this.profile});

  final TeacherProfile profile;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.upload_file_outlined),
                const SizedBox(width: 10),
                Text(s.cvUpload, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(s.cvUploadBlocked, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(s.cvUploadBlockedDesc, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _SavedJobsList extends StatelessWidget {
  const _SavedJobsList({required this.savedJobs, required this.service});

  final BookmarkService savedJobs;
  final TeachingService service;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: savedJobs,
      builder: (context, _) {
        final ids = savedJobs.ids;
        if (ids.isEmpty) {
          return EmptyView(
            icon: Icons.bookmark_border,
            title: AppLocalizations.of(context).noSavedAds,
            message: AppLocalizations.of(context).noSavedAdsHint,
          );
        }
        return FutureBuilder<List<TeachingVacancy?>>(
          future: Future.wait(ids.map(service.getVacancy)),
          builder: (context, snapshot) {
            final vacancies = (snapshot.data ?? [])
                .whereType<TeachingVacancy>()
                .toList();
            if (vacancies.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              children: vacancies
                  .map(
                    (v) => TeachingVacancyCard(
                      vacancy: v,
                      isSaved: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VacancyDetailsScreen(
                            vacancy: v,
                            bookmarks: savedJobs,
                          ),
                        ),
                      ),
                      onToggleSave: () => savedJobs.toggle(v.id),
                    ),
                  )
                  .toList(),
            );
          },
        );
      },
    );
  }
}
