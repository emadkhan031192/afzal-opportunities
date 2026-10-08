import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/brand_colors.dart';
import '../core/utils/deadline.dart';

/// Colors for a deadline pill.
class _BadgePalette {
  const _BadgePalette(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

/// Pill showing an advertisement's deadline label, plus a NEW pill when the
/// advertisement was recently published.
///
/// The deadline is the hero element: tinted backgrounds signal urgency at a
/// glance (mint → amber → red). Set [expanded] to render a full-width,
/// 40dp-tall hero pill for advertisement cards.
class DeadlineBadge extends StatelessWidget {
  const DeadlineBadge({
    super.key,
    required this.info,
    this.compact = false,
    this.expanded = false,
  });

  final DeadlineInfo info;
  final bool compact;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final palette = _palette(context, info.tone);
    final pills = <Widget>[
      if (info.isNew) ...[
        _Pill(
          label: 'NEW',
          icon: Icons.auto_awesome_outlined,
          background: BrandColors.mint,
          foreground: BrandColors.nightBlack,
          compact: compact,
          expanded: false,
        ),
        SizedBox(width: compact ? 6 : 8),
      ],
      _Pill(
        label: info.label,
        icon: Icons.schedule_outlined,
        background: palette.background,
        foreground: palette.foreground,
        compact: compact,
        expanded: expanded,
      ),
    ];
    if (expanded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (info.isNew) ...[const _NewTag(), const SizedBox(height: 6)],
          pills.last,
        ],
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: pills);
  }

  _BadgePalette _palette(BuildContext context, DeadlineTone tone) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    switch (tone) {
      case DeadlineTone.danger:
        return const _BadgePalette(
          BrandColors.dangerTint,
          BrandColors.dangerStrong,
        );
      case DeadlineTone.warning:
        return const _BadgePalette(
          BrandColors.amberTint,
          BrandColors.amberStrong,
        );
      case DeadlineTone.success:
        return _BadgePalette(
          BrandColors.mint.withValues(alpha: 0.16),
          dark ? BrandColors.mint : BrandColors.mintDark,
        );
      case DeadlineTone.info:
        return const _BadgePalette(Color(0xFFE8F0FF), Color(0xFF2B5CB8));
      case DeadlineTone.neutral:
        return _BadgePalette(
          dark ? const Color(0xFF2A2F55) : const Color(0xFFE9EDF3),
          dark ? const Color(0xFFB9BED6) : const Color(0xFF5A6076),
        );
    }
  }
}

/// Compact mint "NEW" tag used above the expanded hero pill.
class _NewTag extends StatelessWidget {
  const _NewTag();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: BrandColors.mint,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'NEW',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: BrandColors.nightBlack,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.compact,
    required this.expanded,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final bool compact;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: expanded ? 16 : 12, color: foreground),
        SizedBox(width: expanded ? 8 : 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: expanded ? 13 : (compact ? 10 : 11),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: foreground,
            ),
          ),
        ),
      ],
    );
    return Container(
      width: expanded ? double.infinity : null,
      height: expanded ? 40 : null,
      padding: expanded
          ? const EdgeInsets.symmetric(horizontal: 12)
          : EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 4 : 6,
            ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(expanded ? 12 : 999),
      ),
      alignment: expanded ? Alignment.center : null,
      child: content,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
          color: dark ? BrandColors.mint : BrandColors.mintDark,
        ),
      ),
    );
  }
}
