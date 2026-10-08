import 'package:flutter/material.dart';

import '../core/theme/brand_colors.dart';
import '../core/utils/deadline.dart';
import '../models/advertisement.dart';
import 'deadline_badge.dart';

/// Large hero card for the featured advertisement.
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
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF232A5C), BrandColors.nightBlack],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _FeaturedPill(),
                  const SizedBox(width: 8),
                  CategoryPill(categoryId: ad.category),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ad.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ad.organization,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFB9BED6)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  DeadlineBadge(info: info),
                  const Spacer(),
                  const Icon(Icons.arrow_forward, color: BrandColors.mint),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedPill extends StatelessWidget {
  const _FeaturedPill();

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
