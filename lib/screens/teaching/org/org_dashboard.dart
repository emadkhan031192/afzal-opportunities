import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../models/teaching_accounts.dart';
import '../../../models/teaching_vacancy.dart';
import '../../../services/teaching_auth.dart';
import '../../../services/teaching_service.dart';
import '../../../widgets/state_views.dart';
import '../../../widgets/delete_account_button.dart';
import '../auth/verify_email_screen.dart';
import 'vacancy_form_screen.dart';

/// Organization dashboard: profile status, vacancy submission, and the
/// organization's own vacancies across all approval statuses.
class OrgDashboard extends StatefulWidget {
  const OrgDashboard({super.key, required this.auth, required this.service});

  final TeachingAuth auth;
  final TeachingService service;

  @override
  State<OrgDashboard> createState() => _OrgDashboardState();
}

class _OrgDashboardState extends State<OrgDashboard> {
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final uid = widget.auth.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.myVacancies),
        actions: [
          DeleteAccountButton(auth: widget.auth, service: widget.service),
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
      body: FutureBuilder<TeachingOrganization?>(
        future: widget.service.getMyOrganization(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final org = snapshot.data;
          if (org == null) {
            return ErrorView(
              message: s.somethingWentWrong,
              onRetry: () async {
                setState(() {});
              },
            );
          }
          return _DashboardBody(
            auth: widget.auth,
            service: widget.service,
            org: org,
            onChanged: () => setState(() {}),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const VacancyFormScreen()),
          );
          if (changed == true && mounted) setState(() {});
        },
        icon: const Icon(Icons.add),
        label: Text(s.postVacancy),
      ),
    );
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody({
    required this.auth,
    required this.service,
    required this.org,
    required this.onChanged,
  });

  final TeachingAuth auth;
  final TeachingService service;
  final TeachingOrganization org;
  final VoidCallback onChanged;

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  late final Stream<List<TeachingVacancy>> _vacanciesStream;

  @override
  void initState() {
    super.initState();
    _vacanciesStream = widget.service.watchMyVacancies(
      widget.auth.currentUser!.uid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    final service = widget.service;
    final org = widget.org;
    final onChanged = widget.onChanged;
    return RefreshIndicator(
      onRefresh: () async => onChanged(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
        children: [
          if (!auth.isEmailVerified)
            _VerifyBanner(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
                );
              },
            ),
          _StatusCard(org: org),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).myVacancies,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<TeachingVacancy>>(
            stream: _vacanciesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: LoadingView(),
                );
              }
              final vacancies = snapshot.data ?? [];
              if (vacancies.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: EmptyView(
                    icon: Icons.work_outline,
                    title: AppLocalizations.of(context).noVacanciesFound,
                    message: AppLocalizations.of(context).vacancySubmittedDesc,
                  ),
                );
              }
              return Column(
                children: vacancies
                    .map(
                      (v) => _VacancyRow(
                        vacancy: v,
                        service: service,
                        onChanged: onChanged,
                      ),
                    )
                    .toList(),
              );
            },
          ),
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
  const _StatusCard({required this.org});

  final TeachingOrganization org;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    String statusText;
    Color color;
    String? desc;
    switch (org.approvalStatus) {
      case TeachingApproval.approved:
        statusText = s.statusApproved;
        color = Colors.green.shade700;
        break;
      case TeachingApproval.rejected:
        statusText = s.statusRejected;
        color = theme.colorScheme.error;
        desc = org.rejectionReason != null
            ? '${s.rejectedDesc} ${org.rejectionReason}'
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
                const Icon(Icons.business_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    org.institutionName,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
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

class _VacancyRow extends StatelessWidget {
  const _VacancyRow({
    required this.vacancy,
    required this.service,
    required this.onChanged,
  });

  final TeachingVacancy vacancy;
  final TeachingService service;
  final VoidCallback onChanged;

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case TeachingApproval.approved:
        return Colors.green.shade700;
      case TeachingApproval.rejected:
      case TeachingApproval.suspended:
        return Theme.of(context).colorScheme.error;
      case TeachingApproval.pending:
      default:
        return Colors.orange.shade800;
    }
  }

  String _statusText(AppLocalizations s, String status) {
    switch (status) {
      case TeachingApproval.approved:
        return s.statusApproved;
      case TeachingApproval.rejected:
        return s.statusRejected;
      case TeachingApproval.suspended:
        return s.statusSuspended;
      case TeachingApproval.pending:
      default:
        return s.statusPending;
    }
  }

  Future<void> _delete(BuildContext context) async {
    final s = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteVacancy),
        content: Text(s.deleteVacancyConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await service.deleteVacancy(vacancy.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.vacancyDeleted)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.unknownError)));
      }
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final v = vacancy;
    final color = _statusColor(context, v.approvalStatus);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(v.jobTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${v.district} · ${v.subjects.take(3).join(', ')}'),
            if (v.applicationDeadline != null)
              Text(
                '${s.applicationDeadline}: '
                '${DateFormat('d MMM yyyy').format(v.applicationDeadline!)}',
              ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _statusText(s, v.approvalStatus),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => VacancyFormScreen(existing: v),
                ),
              );
              if (changed == true) onChanged();
            } else if (value == 'delete') {
              await _delete(context);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text(s.editVacancy)),
            PopupMenuItem(value: 'delete', child: Text(s.deleteVacancy)),
          ],
        ),
      ),
    );
  }
}
