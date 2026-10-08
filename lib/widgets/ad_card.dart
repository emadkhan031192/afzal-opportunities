import 'package:flutter/material.dart';

import '../core/theme/brand_colors.dart';
import '../core/utils/deadline.dart';
import '../models/advertisement.dart';
import '../services/bookmark_service.dart';
import 'deadline_badge.dart';
import 'poster_image.dart';

/// Streaming-style advertisement card for the feed.
///
/// Shows the poster thumbnail, category, deadline badge, bold headline,
/// organization and a bookmark control. Tapping opens the details screen.
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
    final info = getDeadlineInfo(
      lastDate: ad.lastDate,
      publishedAt: ad.publishedAt,
    );
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PosterImage(
                url: ad.posterUrl,
                width: 84,
                height: 84,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CategoryPill(categoryId: ad.category),
                        const SizedBox(width: 6),
                        Expanded(
                          child: DeadlineBadge(info: info, compact: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ad.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ad.organization,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: bookmarks,
                builder: (context, _) {
                  final saved = bookmarks.isBookmarked(ad.id);
                  return IconButton(
                    icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                    color: saved ? BrandColors.mint : null,
                    tooltip: saved ? 'Remove bookmark' : 'Save advertisement',
                    onPressed: () => bookmarks.toggle(ad.id),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
