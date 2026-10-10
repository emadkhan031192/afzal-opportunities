import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/utils/deadline.dart';
import '../../core/utils/share_text.dart';
import '../../core/utils/url_utils.dart';
import '../../models/teaching_vacancy.dart';
import '../../services/bookmark_service.dart';
import '../../services/teaching_auth.dart';
import '../../services/teaching_service.dart';
import '../../widgets/deadline_badge.dart';
import '../../widgets/whatsapp_template_sheet.dart';
import 'auth/login_screen.dart';

/// Full teaching-vacancy view: headline, institution, key facts, urgency
/// badge, description, how-to-apply instructions and a share button.
///
/// Only data the organization provided is shown — missing fields are
/// labeled "Not specified", never invented.
class VacancyDetailsScreen extends StatefulWidget {
  const VacancyDetailsScreen({
    super.key,
    required this.vacancy,
    required this.bookmarks,
  });

  final TeachingVacancy vacancy;
  final BookmarkService bookmarks;

  @override
  State<VacancyDetailsScreen> createState() => _VacancyDetailsScreenState();
}

class _VacancyDetailsScreenState extends State<VacancyDetailsScreen> {
  final TeachingAuth _auth = TeachingAuth();
  final TeachingService _service = TeachingService();
  TeachingVacancy? _mergedVacancy;

  TeachingVacancy get vacancy => _mergedVacancy ?? widget.vacancy;
  BookmarkService get bookmarks => widget.bookmarks;

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
  /// vacancy. Guests never fetch them (and Firestore would deny it).
  Future<void> _loadContact() async {
    if (!_auth.isSignedIn) {
      if (mounted && _mergedVacancy != null) {
        setState(() => _mergedVacancy = null);
      }
      return;
    }
    final contact = await _service.getVacancyContact(widget.vacancy.id);
    if (mounted && contact != null) {
      setState(() => _mergedVacancy = widget.vacancy.withContact(contact));
    }
  }

  Future<void> _share(BuildContext context) async {
    final v = vacancy;
    final text = buildVacancyShareText(v, forWhatsApp: false);
    await SharePlus.instance.share(
      ShareParams(text: text, subject: v.jobTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppLocalizations.of(context);
    final v = vacancy;
    final info = getDeadlineInfo(
      lastDate: v.applicationDeadline,
      publishedAt: v.publishedAt,
    );
    final expired = TeachingService.isExpired(v);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.teaching),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: s.share,
            onPressed: () => _share(context),
          ),
          AnimatedBuilder(
            animation: bookmarks,
            builder: (context, _) {
              final saved = bookmarks.isBookmarked(v.id);
              return IconButton(
                icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                tooltip: s.saveJob,
                onPressed: () => bookmarks.toggle(v.id),
              );
            },
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
            Text(v.jobTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.school_outlined,
                  size: 18,
                  color: BrandColors.mintDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    v.institutionName,
                    style: theme.textTheme.titleMedium,
                  ),
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
                  child: Text(
                    '${v.district}${(v.city ?? '').isNotEmpty ? ' · ${v.city}' : ''}',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FactsGrid(vacancy: v),
            const SizedBox(height: 20),
            Text(s.jobDescription, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(v.description, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            Text(s.howToApply, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            _ApplyBox(vacancy: v, auth: _auth),
            if (expired) ...[
              const SizedBox(height: 16),
              _ExpiredNote(expiredLabel: s.expired),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _ApplyBar(vacancy: v, auth: _auth),
    );
  }
}

/// Key facts grid: subjects, qualification, experience, positions,
/// salary, employment type, posted date.
class _FactsGrid extends StatelessWidget {
  const _FactsGrid({required this.vacancy});

  final TeachingVacancy vacancy;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final v = vacancy;
    final facts = <_Fact>[
      _Fact(
        s.subjectsRequired,
        v.subjects.isEmpty ? s.notSpecified : v.subjects.join(', '),
      ),
      _Fact(s.qualificationRequired, v.qualification),
      _Fact(
        s.experienceRequired,
        (v.experienceRequired ?? '').isEmpty
            ? s.notSpecified
            : v.experienceRequired!,
      ),
      _Fact(s.positions, '${v.positionsCount}'),
      _Fact(s.salaryRange, v.salaryDisplay ?? s.notSpecified),
      _Fact(
        s.employmentType,
        (v.employmentType ?? '').isEmpty ? s.notSpecified : v.employmentType!,
      ),
      _Fact(
        s.postedOn,
        v.publishedAt != null
            ? DateFormat('d MMM yyyy').format(v.publishedAt!)
            : s.notSpecified,
      ),
      _Fact(
        s.applicationDeadline,
        v.applicationDeadline != null
            ? DateFormat('d MMM yyyy').format(v.applicationDeadline!)
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
/// Signed-in teachers see the institution's enabled application methods
/// (Call / WhatsApp / Email) plus any legacy application link. Guests see
/// a login prompt instead — contact details are never shown to guests.
class _ApplyBox extends StatelessWidget {
  const _ApplyBox({required this.vacancy, required this.auth});

  final TeachingVacancy vacancy;
  final TeachingAuth auth;

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
              ? _SignedInMethods(vacancy: vacancy)
              : _GuestPrompt(vacancy: vacancy, auth: auth),
        );
      },
    );
  }
}

/// Application method buttons for signed-in teachers.
class _SignedInMethods extends StatelessWidget {
  const _SignedInMethods({required this.vacancy});

  final TeachingVacancy vacancy;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final v = vacancy;
    final rows = <Widget>[];

    if (v.canCall) {
      rows.add(
        _MethodRow(
          icon: Icons.call_outlined,
          label: '${s.applyByCall}: ${v.applyPhone}',
          onTap: () => openUrl('tel:${v.applyPhone}'),
        ),
      );
    }
    if (v.canWhatsapp) {
      rows.add(
        _MethodRow(
          icon: Icons.chat_outlined,
          label: '${s.applyByWhatsapp}: ${v.applyWhatsapp}',
          onTap: () => WhatsappTemplateSheet.show(context, v),
        ),
      );
    }
    if (v.canEmail) {
      rows.add(
        _MethodRow(
          icon: Icons.email_outlined,
          label: '${s.applyByEmail}: ${v.applyEmail}',
          onTap: () {
            final subject = Uri.encodeComponent(
              'Application: ${v.jobTitle} at ${v.institutionName}',
            );
            openUrl('mailto:${v.applyEmail}?subject=$subject');
          },
        ),
      );
    }
    // Legacy application link (4th optional method).
    final url = (v.applicationUrl ?? '').trim();
    if (url.isNotEmpty) {
      rows.add(
        _MethodRow(icon: Icons.link, label: url, onTap: () => openUrl(url)),
      );
    }
    if ((v.contactInstructions ?? '').trim().isNotEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
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
                  v.contactInstructions!.trim(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
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
class _GuestPrompt extends StatelessWidget {
  const _GuestPrompt({required this.vacancy, required this.auth});

  final TeachingVacancy vacancy;
  final TeachingAuth auth;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.lock_outline,
              size: 18,
              color: BrandColors.mintDark,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.loginToApply,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () async {
            // After login, return to this job (post-login redirect).
            final loggedIn = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => LoginScreen(returnVacancy: vacancy),
              ),
            );
            if (loggedIn == true) auth.reload();
          },
          child: Text(s.login),
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
/// Signed-in teachers get the primary apply action (WhatsApp when
/// available, else the first enabled channel). Guests get a login button
/// that returns them to this job after signing in.
class _ApplyBar extends StatelessWidget {
  const _ApplyBar({required this.vacancy, required this.auth});

  final TeachingVacancy vacancy;
  final TeachingAuth auth;

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
                        text: '${vacancy.jobTitle}\n${vacancy.institutionName}',
                        subject: vacancy.jobTitle,
                      ),
                    ),
                    icon: const Icon(Icons.share_outlined),
                    label: Text(s.share),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: signedIn
                      ? _PrimaryApplyButton(vacancy: vacancy)
                      : ElevatedButton.icon(
                          onPressed: () async {
                            final loggedIn = await Navigator.of(context)
                                .push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        LoginScreen(returnVacancy: vacancy),
                                  ),
                                );
                            if (loggedIn == true) auth.reload();
                          },
                          icon: const Icon(Icons.login),
                          label: Text(s.loginToApplyShort),
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

/// Primary apply action for signed-in teachers: WhatsApp template sheet
/// when available, else call, email, or the legacy application link.
class _PrimaryApplyButton extends StatelessWidget {
  const _PrimaryApplyButton({required this.vacancy});

  final TeachingVacancy vacancy;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final v = vacancy;
    final url = (v.applicationUrl ?? '').trim();
    if (v.canWhatsapp) {
      return _applyButton(
        context,
        icon: Icons.chat_outlined,
        label: s.applyViaWhatsapp,
        onPressed: () => WhatsappTemplateSheet.show(context, v),
      );
    }
    if (v.canCall) {
      return _applyButton(
        context,
        icon: Icons.call_outlined,
        label: s.applyViaCall,
        onPressed: () => openUrl('tel:${v.applyPhone}'),
      );
    }
    if (v.canEmail) {
      return _applyButton(
        context,
        icon: Icons.email_outlined,
        label: s.applyViaEmail,
        onPressed: () {
          final subject = Uri.encodeComponent(
            'Application: ${v.jobTitle} at ${v.institutionName}',
          );
          openUrl('mailto:${v.applyEmail}?subject=$subject');
        },
      );
    }
    if (url.isNotEmpty) {
      return _applyButton(
        context,
        icon: Icons.open_in_new,
        label: s.applyNow,
        onPressed: () => openUrl(url),
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
