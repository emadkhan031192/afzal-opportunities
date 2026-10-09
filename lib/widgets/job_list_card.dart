import 'package:flutter/material.dart';

import '../core/l10n/app_localizations.dart';
import '../core/theme/card_tints.dart';
import '../core/utils/deadline.dart';
import '../models/advertisement.dart';
import 'deadline_badge.dart';

/// List-view advertisement card (v1.3.0): full-width pill card tinted by
/// category, with an organization avatar, title, organization name and an
/// urgency-colored deadline badge. Salary and logos are never invented:
/// the card shows only real ad data.
class JobListCard extends StatelessWidget {
  const JobListCard({
    super.key,
    required this.ad,
    required this.isSaved,
    required this.onTap,
    required this.onToggleSave,
  });

  final Advertisement ad;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onToggleSave;

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
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: tint.background,
        borderRadius: BorderRadius.circular(44),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(44),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                // Organization avatar: initial letter (never a fake logo).
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initial(ad.organization),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _avatarInk(ad.category),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ad.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: tint.ink,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ad.organization,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: tint.subInk),
                      ),
                      const SizedBox(height: 6),
                      DeadlineBadge(info: info, compact: true),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: tint.chip,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _categoryLabel(ad.category, s),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tint.ink,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onToggleSave,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: tint.ink,
                          size: 22,
                        ),
                      ),
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

  static String _initial(String organization) {
    final trimmed = organization.trim();
    return trimmed.isEmpty ? '•' : trimmed[0].toUpperCase();
  }

  /// Avatar letter color: readable on the white circle for every tint.
  static Color _avatarInk(String categoryId) {
    switch (categoryId) {
      case 'scholarships':
        return const Color(0xFF2E7D55);
      case 'admissions':
        return const Color(0xFF9A7418);
      case 'other':
        return const Color(0xFFB05E5E);
      case 'jobs':
      default:
        return const Color(0xFF1F66CC);
    }
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
}
