import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/l10n/app_localizations.dart';
import '../core/theme/brand_colors.dart';
import '../core/theme/card_tints.dart';
import '../core/utils/deadline.dart';
import '../models/advertisement.dart';
import 'deadline_badge.dart';

/// Grid-view advertisement card (v1.3.0 layout):
/// - top metadata row: urgency-colored deadline badge + category chip
/// - ad title as the headline
/// - bottom byline: organization logo circle + organization name
/// - last date line
///
/// Card color is tinted by category (Jobs blue, Scholarships mint,
/// Admissions amber, Other rose) with dark-mode variants. Only real ad
/// data is shown — no invented logos, salaries or applicant counts.
class JobGridCard extends StatelessWidget {
  const JobGridCard({
    super.key,
    required this.ad,
    required this.onTap,
  });

  final Advertisement ad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = cardTintForCategory(ad.category, dark);
    final s = AppLocalizations.of(context);
    final info = getDeadlineInfo(
      lastDate: ad.lastDate,
      publishedAt: ad.publishedAt,
    );

    return Container(
      decoration: BoxDecoration(
        color: tint.background,
        borderRadius: BorderRadius.circular(36),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metadata row: urgency badge + category chip grouped.
                Row(
                  children: [
                    Flexible(child: DeadlineBadge(info: info, compact: true)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: tint.chip,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _categoryLabel(ad.category, s),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: tint.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Headline: the advertisement title.
                Text(
                  ad.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: tint.ink,
                    height: 1.2,
                  ),
                ),
                const Spacer(),
                // Byline: organization logo circle + name.
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initial(ad.organization),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: BrandColors.nightBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ad.organization,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: tint.subInk,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${s.lastDate}: ${_lastDateLabel(ad, s)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: tint.subInk.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _initial(String organization) {
    final trimmed = organization.trim();
    return trimmed.isEmpty ? '•' : trimmed[0].toUpperCase();
  }

  static String _categoryLabel(String id, AppLocalizations s) {
    switch (id) {
      case 'jobs':
        return s.jobs;
      case 'scholarships':
        return s.scholarships;
      case 'admissions':
        return s.admissions;
      case 'other':
      default:
        return s.other;
    }
  }

  static String _lastDateLabel(Advertisement ad, AppLocalizations s) {
    final lastDate = ad.lastDate;
    if (lastDate == null) return s.notSpecified;
    return DateFormat('d MMMM yyyy').format(lastDate);
  }
}
