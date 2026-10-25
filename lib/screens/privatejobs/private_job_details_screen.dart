import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/utils/deadline.dart';
import '../../core/utils/share_text.dart';
import '../../core/utils/url_utils.dart';
import '../../models/private_job.dart';
import '../../services/private_job_service.dart';
import '../../services/teaching_auth.dart';
import '../../widgets/deadline_badge.dart';
import '../../widgets/whatsapp_template_sheet.dart';

/// Full private-job view: headline, company, key facts, urgency badge,
/// description, how-to-apply instructions and a share button.
///
/// Mirrors [VacancyDetailsScreen]: only data the poster provided is
/// shown — missing fields are labeled "Not specified", never invented.
/// Contact details are shown only to signed-in users (they live in the
/// private privateJobContacts collection); guests see the login prompt.
class PrivateJobDetailsScreen extends StatefulWidget {
  const PrivateJobDetailsScreen({
    super.key,
    required this.job,
    this.onOpenProfile,
  });

  final PrivateJob job;

  /// Jumps to the Profile tab (apply-instructions prompt). Null when the
  /// screen is opened from a context without MainShell tabs.
  final VoidCallback? onOpenProfile;

  @override
  State<PrivateJobDetailsScreen> createState() =>
      _PrivateJobDetailsScreenState();
}

class _PrivateJobDetailsScreenState extends State<PrivateJobDetailsScreen> {
  final TeachingAuth _auth = TeachingAuth();
  final PrivateJobService _service = PrivateJobService();
  PrivateJob? _mergedJob;

  PrivateJob get job => _mergedJob ?? widget.job;

  @override
  void initState() {
    super.initState();
    _loadContact();
    _auth.addListener(_loadContact);
  }

  @override
  void dispose() {
    _auth.removeListener(_loadContact);
    super.dispose();
  }

  /// For signed-in users, merges the private contact details into the
  /// job. Guests never fetch them (and Firestore would deny it).
  Future<void> _loadContact() async {
    if (!_auth.isSignedIn) {
      if (mounted && _mergedJob != null) {
        setState(() => _mergedJob = null);
      }
      return;
    }
    final contact = await _service.getJobContact(widget.job.id);
    if (mounted && contact != null) {
      setState(() => _mergedJob = widget.job.withContact(contact));
    }
  }

  Future<void> _share(BuildContext context) async {
    final j = job;
    final text = buildPrivateJobShareText(j, forWhatsApp: false);
    await SharePlus.instance.share(ShareParams(text: text, subject: j.title));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppLocalizations.of(context);
    final j = job;
    final info = getDeadlineInfo(
      lastDate: j.deadline,
      publishedAt: j.publishedAt,
    );
    final expired = PrivateJobService.isExpired(j);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.privateJobs),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: s.share,
            onPressed: () => _share(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DeadlineBadge(info: info, expanded: true),
            const SizedBox(height: 16),
            Text(j.title, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.business_outlined,
                  size: 18,
                  color: BrandColors.mintDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(j.company, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: BrandColors.mintDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(j.city, style: theme.textTheme.titleSmall),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FactsGrid(job: j),
            const SizedBox(height: 20),
            Text(s.jobDescription, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(j.description, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            Text(s.howToApply, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            _ApplyBox(job: j, auth: _auth, onOpenProfile: widget.onOpenProfile),
            if (expired) ...[
              const SizedBox(height: 16),
              _ExpiredNote(expiredLabel: s.expired),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _ApplyBar(
        job: j,
        auth: _auth,
        onOpenProfile: widget.onOpenProfile,
      ),
    );
  }
}

/// Key facts grid: company, city, salary, posted date, deadline.
class _FactsGrid extends StatelessWidget {
  const _FactsGrid({required this.job});

  final PrivateJob job;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final j = job;
    final facts = <_Fact>[
      _Fact(s.company, j.company),
      _Fact(s.city, j.city),
      _Fact(
        s.salary,
        (j.salary ?? '').trim().isEmpty ? s.notSpecified : j.salary!.trim(),
      ),
      _Fact(
        s.postedOn,
        j.publishedAt != null
            ? DateFormat('d MMM yyyy').format(j.publishedAt!)
            : s.notSpecified,
      ),
      _Fact(
        s.applicationDeadline,
        j.deadline != null
            ? DateFormat('d MMM yyyy').format(j.deadline!)
            : s.notSpecified,
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.6,
      ),
      itemCount: facts.length,
      itemBuilder: (context, i) => _FactCard(fact: facts[i]),
    );
  }
}

class _Fact {
  const _Fact(this.label, this.value);

  final String label;
  final String value;
}

class _FactCard extends StatelessWidget {
  const _FactCard({required this.fact});

  final _Fact fact;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.06)
            : BrandColors.lightBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            fact.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 2),
          Text(
            fact.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// How-to-apply box.
///
/// Signed-in users see the poster's enabled application methods
/// (Call / WhatsApp / Email). Guests see a login prompt instead —
/// contact details are never shown to guests.
class _ApplyBox extends StatelessWidget {
  const _ApplyBox({required this.job, required this.auth, this.onOpenProfile});

  final PrivateJob job;
  final TeachingAuth auth;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: auth,
      builder: (context, _) {
        final signedIn = auth.isSignedIn;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: BrandColors.mint.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: signedIn
              ? _SignedInMethods(job: job)
              : _ApplyInstructionsBox(onOpenProfile: onOpenProfile),
        );
      },
    );
  }
}

/// Application method buttons for signed-in users.
class _SignedInMethods extends StatelessWidget {
  const _SignedInMethods({required this.job});

  final PrivateJob job;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final j = job;
    final rows = <Widget>[];

    if (j.canCall) {
      rows.add(
        _MethodRow(
          icon: Icons.call_outlined,
          label: '${s.applyByCall}: ${j.applyPhone}',
          onTap: () => openUrl('tel:${j.applyPhone}'),
        ),
      );
    }
    if (j.canWhatsapp) {
      rows.add(
        _MethodRow(
          icon: Icons.chat_outlined,
          label: '${s.applyByWhatsapp}: ${j.applyWhatsapp}',
          onTap: () => WhatsappTemplateSheet.showForJob(
            context,
            jobTitle: j.title,
            posterName: j.company,
            city: j.city,
            whatsappInternational: j.whatsappInternational,
          ),
        ),
      );
    }
    if (j.canEmail) {
      rows.add(
        _MethodRow(
          icon: Icons.email_outlined,
          label: '${s.applyByEmail}: ${j.applyEmail}',
          onTap: () {
            final subject = Uri.encodeComponent(
              'Application: ${j.title} at ${j.company}',
            );
            openUrl('mailto:${j.applyEmail}?subject=$subject');
          },
        ),
      );
    }
    if (rows.isEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            s.notSpecified,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _MethodRow extends StatelessWidget {
  const _MethodRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 20, color: BrandColors.mintDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: BrandColors.mintDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Guests see a login prompt instead of contact details.
class _ApplyInstructionsBox extends StatelessWidget {
  const _ApplyInstructionsBox({this.onOpenProfile});

  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline,
              size: 18,
              color: BrandColors.mintDark,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.applyInstructions,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: onOpenProfile,
          icon: const Icon(Icons.person_outline),
          label: Text(s.goToProfile),
        ),
      ],
    );
  }
}

class _ExpiredNote extends StatelessWidget {
  const _ExpiredNote({required this.expiredLabel});

  final String expiredLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrandColors.dangerTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_busy_outlined,
            color: BrandColors.dangerStrong,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              expiredLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: BrandColors.dangerStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sticky bottom apply bar.
///
/// Signed-in users get the primary apply action (WhatsApp when
/// available, else the first enabled channel). Guests get a login button
/// that returns them to this job after signing in.
class _ApplyBar extends StatelessWidget {
  const _ApplyBar({required this.job, required this.auth, this.onOpenProfile});

  final PrivateJob job;
  final TeachingAuth auth;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: auth,
      builder: (context, _) {
        final signedIn = auth.isSignedIn;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(
                        text: '${job.title}\n${job.company}',
                        subject: job.title,
                      ),
                    ),
                    icon: const Icon(Icons.share_outlined),
                    label: Text(s.share),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: signedIn
                      ? _PrimaryApplyButton(job: job)
                      : ElevatedButton.icon(
                          onPressed: onOpenProfile,
                          icon: const Icon(Icons.person_outline),
                          label: Text(s.goToProfile),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BrandColors.mockupBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Primary apply action for signed-in users: WhatsApp template sheet
/// when available, else call or email.
class _PrimaryApplyButton extends StatelessWidget {
  const _PrimaryApplyButton({required this.job});

  final PrivateJob job;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final j = job;
    if (j.canWhatsapp) {
      return _applyButton(
        context,
        icon: Icons.chat_outlined,
        label: s.applyViaWhatsapp,
        onPressed: () => WhatsappTemplateSheet.showForJob(
          context,
          jobTitle: j.title,
          posterName: j.company,
          city: j.city,
          whatsappInternational: j.whatsappInternational,
        ),
      );
    }
    if (j.canCall) {
      return _applyButton(
        context,
        icon: Icons.call_outlined,
        label: s.applyViaCall,
        onPressed: () => openUrl('tel:${j.applyPhone}'),
      );
    }
    if (j.canEmail) {
      return _applyButton(
        context,
        icon: Icons.email_outlined,
        label: s.applyViaEmail,
        onPressed: () {
          final subject = Uri.encodeComponent(
            'Application: ${j.title} at ${j.company}',
          );
          openUrl('mailto:${j.applyEmail}?subject=$subject');
        },
      );
    }
    return _applyButton(
      context,
      icon: Icons.how_to_reg_outlined,
      label: s.applyNow,
      onPressed: () {},
    );
  }

  Widget _applyButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: BrandColors.mockupBlue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
