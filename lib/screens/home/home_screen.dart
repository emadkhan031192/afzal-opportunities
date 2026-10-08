import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/utils/deadline.dart';
import '../../models/advertisement.dart';
import '../../services/advertisement_service.dart';
import '../../services/bookmark_service.dart';
import '../../widgets/ad_card.dart';
import '../../widgets/category_chips.dart';
import '../../widgets/featured_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import '../details/details_screen.dart';

/// Discovery feed: brand header, featured card, closing-soon rail,
/// category filters, sort control and the latest advertisements list.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.service,
    required this.bookmarks,
  });

  final AdvertisementService service;
  final BookmarkService bookmarks;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _category = AppConstants.allCategoriesId;
  AdSortMode _sort = AdSortMode.relevance;
  late Future<List<Advertisement>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchPublished();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.service.fetchPublished();
    });
    await _future;
  }

  void _openDetails(Advertisement ad) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailsScreen(
          ad: ad,
          bookmarks: widget.bookmarks,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Advertisement>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorView(
              message:
                  'Could not load advertisements. Check your connection and try again.',
              onRetry: _refresh,
            );
          }
          return _buildFeed(context, snapshot.data ?? <Advertisement>[]);
        },
      ),
    );
  }

  Widget _buildFeed(BuildContext context, List<Advertisement> all) {
    final now = DateTime.now();
    final active = filterActiveAds(all, now: now);
    final ranked = sortAds(active, AdSortMode.relevance, now: now);

    Advertisement? featured;
    for (final ad in ranked) {
      if (ad.isFeatured) {
        featured = ad;
        break;
      }
    }
    featured ??= ranked.isEmpty ? null : ranked.first;

    final closingSoon =
        sortAds(active, AdSortMode.nearestDeadline, now: now).where((ad) {
      final daysLeft = getDeadlineInfo(
        lastDate: ad.lastDate,
        now: now,
      ).daysLeft;
      return daysLeft != null &&
          daysLeft >= 0 &&
          daysLeft <= 7 &&
          ad.id != featured?.id;
    }).toList();

    var latest = sortAds(
      filterByCategory(active, _category),
      _sort,
      now: now,
    );
    if (featured != null) {
      final featuredId = featured.id;
      latest = latest.where((ad) => ad.id != featuredId).toList();
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _brandHeader(context)),
        if (featured != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: FeaturedCard(
                ad: featured,
                onTap: () => _openDetails(featured!),
              ),
            ),
          ),
        if (closingSoon.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Closing soon',
              icon: Icons.timer_outlined,
            ),
          ),
          SliverToBoxAdapter(child: _closingSoonRow(closingSoon)),
        ],
        SliverToBoxAdapter(
          child: CategoryChips(
            selected: _category,
            onSelected: (id) => setState(() => _category = id),
          ),
        ),
        SliverToBoxAdapter(child: _sortRow()),
        const SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Latest advertisements',
            icon: Icons.fiber_new_outlined,
          ),
        ),
        if (latest.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyView(
              icon: Icons.search_off_outlined,
              title: 'No advertisements found',
              message: 'Try a different category or pull down to refresh.',
            ),
          )
        else
          _adsSliver(latest),
      ],
    );
  }

  Widget _brandHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [BrandColors.mint, Color(0xFF3E9E7B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppConstants.brandName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: BrandColors.nightBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConstants.tagline,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: BrandColors.nightBlack.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: BrandColors.nightBlack.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.work_outline,
                color: BrandColors.nightBlack,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _closingSoonRow(List<Advertisement> ads) {
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ads.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final ad = ads[index];
          return SizedBox(
            width: 300,
            child: AdCard(
              ad: ad,
              bookmarks: widget.bookmarks,
              onTap: () => _openDetails(ad),
            ),
          );
        },
      ),
    );
  }

  Widget _sortRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Icon(
            Icons.sort,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SegmentedButton<AdSortMode>(
              segments: const [
                ButtonSegment(
                  value: AdSortMode.relevance,
                  label: Text('Relevance'),
                  icon: Icon(Icons.auto_awesome_outlined),
                ),
                ButtonSegment(
                  value: AdSortMode.nearestDeadline,
                  label: Text('Deadline'),
                  icon: Icon(Icons.schedule_outlined),
                ),
              ],
              selected: {_sort},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                setState(() => _sort = selection.first);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _adsSliver(List<Advertisement> ads) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        if (constraints.crossAxisExtent > 700) {
          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final ad = ads[index];
                  return AdCard(
                    ad: ad,
                    bookmarks: widget.bookmarks,
                    onTap: () => _openDetails(ad),
                  );
                },
                childCount: ads.length,
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 420,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 3.1,
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final ad = ads[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AdCard(
                    ad: ad,
                    bookmarks: widget.bookmarks,
                    onTap: () => _openDetails(ad),
                  ),
                );
              },
              childCount: ads.length,
            ),
          ),
        );
      },
    );
  }
}
