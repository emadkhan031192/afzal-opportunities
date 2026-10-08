import 'package:flutter/material.dart';

import '../core/theme/brand_colors.dart';
import '../core/utils/deadline.dart';
import '../models/advertisement.dart';

/// List-view advertisement card recreating the user's designed Page 2:
/// full-width pill cards alternating pastel yellow and mockup blue, with an
/// organization avatar, title, organization name and a deadline chip.
/// Salary and logos are never invented: the card shows only real ad data.
class JobListCard extends StatelessWidget {
  const JobListCard({
    super.key,
    required this.ad,
    required this.index,
    required this.isSaved,
    required this.onTap,
    required this.onToggleSave,
  });

  final Advertisement ad;
  final int index;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onToggleSave;

  bool get _isBlue => index.isOdd;

  @override
  Widget build(BuildContext context) {
    final blue = _isBlue;
    final bg = blue ? BrandColors.mockupBlue : BrandColors.cardYellow;
    final ink = blue ? Colors.white : BrandColors.nightBlue;
    final subInk = blue
        ? Colors.white.withValues(alpha: 0.82)
        : BrandColors.nightBlue.withValues(alpha: 0.62);
    final info = getDeadlineInfo(
      lastDate: ad.lastDate,
      publishedAt: ad.publishedAt,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: bg,
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
                      color: blue
                          ? BrandColors.mockupBlue
                          : BrandColors.nightBlue,
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
                          color: ink,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ad.organization,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: subInk),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _DeadlineChip(info: info, dark: blue),
                    GestureDetector(
                      onTap: onToggleSave,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: ink,
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
}

/// Compact deadline chip shown on list cards. Renders nothing when the ad
/// has no deadline and is not new.
class _DeadlineChip extends StatelessWidget {
  const _DeadlineChip({required this.info, required this.dark});

  final DeadlineInfo info;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final label = _shortLabel(info);
    if (label == null) return const SizedBox.shrink();
    final bg = dark ? Colors.white : BrandColors.nightBlue;
    final fg = dark ? BrandColors.nightBlue : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  static String? _shortLabel(DeadlineInfo info) {
    final days = info.daysLeft;
    if (days == null) {
      return info.isNew ? 'NEW' : null;
    }
    if (days < 0) return 'EXPIRED';
    if (days == 0) return 'TODAY';
    if (days == 1) return '1 DAY LEFT';
    return '$days DAYS LEFT';
  }
}
