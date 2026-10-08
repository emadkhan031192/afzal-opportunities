import 'package:flutter/material.dart';

import '../core/theme/brand_colors.dart';
import '../core/utils/deadline.dart';
import '../models/advertisement.dart';
import '../services/bookmark_service.dart';
import 'deadline_badge.dart';
import 'poster_image.dart';

/// Modern advertisement card for the feed.
///
/// Layout: poster thumbnail + headline/organization row with a bookmark
/// control, and a full-width deadline pill as the hero element so the
/// countdown is impossible to miss. Tapping opens the details screen.
class AdCard extends StatelessWidget {
  const AdCard({
    super.key,
    required this.ad,
    required this.bookmarks,
    required this.onTap,
  });

  final Advertisement ad;
  final BookmarkService bookmarks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = getDeadlineInfo(
      lastDate: ad.lastDate,
      publishedAt: ad.publishedAt,
    );
    final location = (ad.location ?? '').trim();
    final orgLine = location.isEmpty
        ? ad.organization
        : '${ad.organization} • $location';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PosterImage(
                    url: ad.posterUrl,
                    width: 84,
                    height: 84,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ad.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          orgLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CategoryPill(categoryId: ad.category),
                            if (info.isNew) ...[
                              const SizedBox(width: 6),
                              const _NewPill(),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 48,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AnimatedBuilder(
                          animation: bookmarks,
                          builder: (context, _) {
                            final saved = bookmarks.isBookmarked(ad.id);
                            return IconButton(
                              icon: Icon(
                                saved ? Icons.bookmark : Icons.bookmark_border,
                              ),
                              color: saved ? BrandColors.mint : null,
                              tooltip: saved
                                  ? 'Remove bookmark'
                                  : 'Save advertisement',
                              onPressed: () => bookmarks.toggle(ad.id),
                            );
                          },
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: BrandColors.mint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: BrandColors.nightBlack,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DeadlineBadge(info: info, expanded: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact mint "NEW" tag shown next to the category chip.
class _NewPill extends StatelessWidget {
  const _NewPill();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
