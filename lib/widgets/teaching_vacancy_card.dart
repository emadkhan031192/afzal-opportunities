import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/l10n/app_localizations.dart';
import '../core/theme/brand_colors.dart';
import '../core/utils/deadline.dart';
import '../models/teaching_vacancy.dart';
import 'deadline_badge.dart';

/// Public vacancy card for the Private Teaching Jobs feed.
///
/// Shows the job title, institution, district/location, subjects,
/// qualification, salary (only when provided — never invented) and an
/// urgency-colored deadline badge. Tapping opens the vacancy details.
class TeachingVacancyCard extends StatelessWidget {
  const TeachingVacancyCard({
    super.key,
    required this.vacancy,
    required this.isSaved,
    required this.onTap,
    required this.onToggleSave,
  });

  final TeachingVacancy vacancy;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onToggleSave;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final s = AppLocalizations.of(context);
    final info = getDeadlineInfo(
      lastDate: vacancy.applicationDeadline,
      publishedAt: vacancy.publishedAt,
    );

    final bg = dark ? const Color(0xFF1E4D3A) : const Color(0xFFE3F3EA);
    final ink = dark ? Colors.white : BrandColors.nightBlue;
    final subInk = dark
        ? const Color(0xFFB9D9C8)
        : BrandColors.nightBlue.withValues(alpha: 0.62);

    final location = [
      vacancy.district,
      if ((vacancy.city ?? '').isNotEmpty) vacancy.city!,
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vacancy.jobTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: ink,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vacancy.institutionName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: subInk,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: subInk,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: subInk),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onToggleSave,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: ink,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                if (vacancy.subjects.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: vacancy.subjects
                        .take(4)
                        .map(
                          (subject) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : Colors.white.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              subject,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ink,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MetaLine(
                        icon: Icons.school_outlined,
                        text: vacancy.qualification,
                        color: subInk,
                      ),
                    ),
                    if (vacancy.salaryDisplay != null) ...[
                      const SizedBox(width: 8),
                      _MetaLine(
                        icon: Icons.payments_outlined,
                        text: vacancy.salaryDisplay!,
                        color: subInk,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    DeadlineBadge(info: info, compact: true),
                    const Spacer(),
                    if (vacancy.applicationDeadline != null)
                      Text(
                        DateFormat(
                          'd MMM yyyy',
                        ).format(vacancy.applicationDeadline!),
                        style: TextStyle(fontSize: 12.5, color: subInk),
                      )
                    else
                      Text(
                        s.notSpecified,
                        style: TextStyle(fontSize: 12.5, color: subInk),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: color),
          ),
        ),
      ],
    );
  }
}
