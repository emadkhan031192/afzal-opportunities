import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/brand_colors.dart';
import '../core/utils/deadline.dart';

/// Colors for a [DeadlineBadge] pill.
class _BadgePalette {
  const _BadgePalette(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

/// Pill showing an advertisement's deadline label, plus a NEW pill when the
/// advertisement was recently published.
class DeadlineBadge extends StatelessWidget {
  const DeadlineBadge({super.key, required this.info, this.compact = false});

  final DeadlineInfo info;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = _palette(context, info.tone);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (info.isNew) ...[
          _Pill(
            label: 'NEW',
            background: BrandColors.mint,
            foreground: BrandColors.nightBlack,
            compact: compact,
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: _Pill(
            label: info.label,
            background: palette.background,
            foreground: palette.foreground,
            compact: compact,
          ),
        ),
      ],
    );
  }

  _BadgePalette _palette(BuildContext context, DeadlineTone tone) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    switch (tone) {
      case DeadlineTone.danger:
        return const _BadgePalette(Color(0xFFE5484D), Colors.white);
      case DeadlineTone.warning:
        return const _BadgePalette(Color(0xFFFFB020), Color(0xFF3A2700));
      case DeadlineTone.success:
        return const _BadgePalette(
          BrandColors.mint,
          BrandColors.nightBlack,
        );
      case DeadlineTone.info:
        return const _BadgePalette(Color(0xFF4C8DFF), Colors.white);
      case DeadlineTone.neutral:
        return _BadgePalette(
          dark ? const Color(0xFF2A2F55) : const Color(0xFFE9EDF3),
          dark ? const Color(0xFFB9BED6) : const Color(0xFF5A6076),
        );
    }
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
    required this.compact,
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: foreground,
        ),
      ),
    );
  }
}

/// Small pill showing the advertisement category next to the deadline badge.
class CategoryPill extends StatelessWidget {
  const CategoryPill({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: dark
            ? BrandColors.mint.withValues(alpha: 0.14)
            : BrandColors.mint.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        AppConstants.categoryLabel(categoryId),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: dark ? BrandColors.mint : const Color(0xFF1F7A5C),
        ),
      ),
    );
  }
}
