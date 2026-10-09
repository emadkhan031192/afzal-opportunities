import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/utils/deadline.dart';
import '../../core/utils/url_utils.dart';
import '../../models/teaching_vacancy.dart';
import '../../services/bookmark_service.dart';
import '../../services/teaching_service.dart';
import '../../widgets/deadline_badge.dart';

/// Full teaching-vacancy view: headline, institution, key facts, urgency
/// badge, description, how-to-apply instructions and a share button.
///
/// Only data the organization provided is shown — missing fields are
/// labeled "Not specified", never invented.
class VacancyDetailsScreen extends StatelessWidget {
  const VacancyDetailsScreen({
    super.key,
    required this.vacancy,
    required this.bookmarks,
  });

  final TeachingVacancy vacancy;
  final BookmarkService bookmarks;

  Future<void> _share(BuildContext context) async {
    final s = AppLocalizations.of(context);
    final v = vacancy;
    final info = getDeadlineInfo(
      lastDate: v.applicationDeadline,
      publishedAt: v.publishedAt,
    );
    final text = StringBuffer()
      ..writeln(v.jobTitle)
      ..writeln(v.institutionName)
      ..writeln(
        '${v.district}'
        '${(v.city ?? '').isNotEmpty ? ' · ${v.city}' : ''}',
      )
      ..writeln(
        '${s.applicationDeadline}: ${v.applicationDeadline != null ? DateFormat('d MMMM yyyy').format(v.applicationDeadline!) : s.notSpecified} (${s.deadlineLabel(info)})',
      )
      ..writeln()
      ..writeln(_short(v.description));
    final link = (v.applicationUrl ?? '').trim();
    if (link.isNotEmpty) text.writeln(link);
    await Share.share(text.toString(), subject: v.jobTitle);
  }

  static String _short(String text) {
    final trimmed = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    return trimmed.length > 220 ? '${trimmed.substring(0, 220)}…' : trimmed;
  }

  Future<void> _openUrl(BuildContext context, String? url) async {
    final opened = await openUrl(url);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).linkOpenFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppLocalizations.of(context);
    final v = vacancy;
    final dark = theme.brightness == Brightness.dark;
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
            _ApplyBox(vacancy: v),
            if (expired) ...[
              const SizedBox(height: 16),
              _ExpiredNote(expiredLabel: s.expired),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _ApplyBar(vacancy: v),
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

/// How-to-apply box: method, contact instructions, application URL.
class _ApplyBox extends StatelessWidget {
  const _ApplyBox({required this.vacancy});

  final TeachingVacancy vacancy;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final v = vacancy;
    final lines = <Widget>[];
    if ((v.applicationMethod ?? '').isNotEmpty) {
      lines.add(
        _line(context, Icons.how_to_reg_outlined, v.applicationMethod!),
      );
    }
    if ((v.contactInstructions ?? '').isNotEmpty) {
      lines.add(
        _line(context, Icons.contact_phone_outlined, v.contactInstructions!),
      );
    }
    if ((v.applicationUrl ?? '').trim().isNotEmpty) {
      lines.add(
        GestureDetector(
          onTap: () => openUrl(v.applicationUrl),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.link, size: 18, color: BrandColors.mockupBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    v.applicationUrl!.trim(),
                    style: const TextStyle(
                      color: BrandColors.mockupBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (lines.isEmpty) {
      lines.add(_line(context, Icons.info_outline, s.notSpecified));
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrandColors.mint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: lines),
    );
  }

  Widget _line(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: BrandColors.mintDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
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

/// Sticky bottom apply bar: opens the application URL when present.
class _ApplyBar extends StatelessWidget {
  const _ApplyBar({required this.vacancy});

  final TeachingVacancy vacancy;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final url = (vacancy.applicationUrl ?? '').trim();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Share.share(
                  '${vacancy.jobTitle}\n${vacancy.institutionName}',
                  subject: vacancy.jobTitle,
                ),
                icon: const Icon(Icons.share_outlined),
                label: Text(s.share),
              ),
            ),
            if (url.isNotEmpty) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => openUrl(url),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(s.applyNow),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandColors.mockupBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
