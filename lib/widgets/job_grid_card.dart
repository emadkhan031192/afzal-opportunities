import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/brand_colors.dart';
import '../core/utils/deadline.dart';
import '../models/advertisement.dart';

/// Grid-view advertisement card recreating the user's designed Page 4:
/// pastel pink/blue cards with a "days left" badge, organization avatar,
/// last date and a category chip. Only real ad data is shown.
class JobGridCard extends StatelessWidget {
  const JobGridCard({
    super.key,
    required this.ad,
    required this.index,
    required this.onTap,
  });

  final Advertisement ad;
  final int index;
  final VoidCallback onTap;

  bool get _isBlue => index.isOdd;

  @override
  Widget build(BuildContext context) {
    final blue = _isBlue;
    final bg = blue ? BrandColors.mockupBlue : BrandColors.cardPink;
    final chipBg = blue
        ? Colors.black.withValues(alpha: 0.18)
        : BrandColors.cardPinkDark;
    final info = getDeadlineInfo(
      lastDate: ad.lastDate,
      publishedAt: ad.publishedAt,
    );

    return Container(
      decoration: BoxDecoration(
        color: bg,
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
                // Days-left badge, top-right (the mockup's hero element).
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _daysLeftLabel(info),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initial(ad.organization),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: blue
                          ? BrandColors.mockupBlue
                          : BrandColors.cardPinkDark,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  ad.organization,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ad.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Last date',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                Text(
                  _lastDateLabel(ad),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    AppConstants.categoryLabel(ad.category),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
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

  static String _daysLeftLabel(DeadlineInfo info) {
    final days = info.daysLeft;
    if (days == null) {
      return info.isNew ? 'NEW' : '';
    }
    if (days <= 0) return 'Closing today';
    if (days == 1) return '1 Day left';
    return '$days Days left';
  }

  static String _lastDateLabel(Advertisement ad) {
    final lastDate = ad.lastDate;
    if (lastDate == null) return 'Not specified';
    return DateFormat('d MMMM yyyy').format(lastDate);
  }
}
