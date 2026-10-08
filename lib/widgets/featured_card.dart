import 'package:flutter/material.dart';

import '../core/theme/brand_colors.dart';
import '../core/utils/deadline.dart';
import '../models/advertisement.dart';
import 'deadline_badge.dart';
import 'poster_image.dart';

/// Wide hero banner for the featured advertisement: poster background with
/// a dark gradient overlay, FEATURED tag, white headline and deadline pill.
class FeaturedCard extends StatelessWidget {
  const FeaturedCard({super.key, required this.ad, required this.onTap});

  final Advertisement ad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = getDeadlineInfo(
      lastDate: ad.lastDate,
      publishedAt: ad.publishedAt,
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PosterImage(url: ad.posterUrl, borderRadius: BorderRadius.zero),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x33000000), Color(0xC4000000)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FeaturedTag(),
                    const Spacer(),
                    Text(
                      ad.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ad.organization,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFD5D9EA),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Spacer(),
                        DeadlineBadge(info: info, compact: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedTag extends StatelessWidget {
  const _FeaturedTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: BrandColors.mint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'FEATURED',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: BrandColors.nightBlack,
        ),
      ),
    );
  }
}
