import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/deadline.dart';
import '../../core/utils/feed_sort.dart';
import '../../models/advertisement.dart';
import '../../services/advertisement_service.dart';
import '../../services/bookmark_service.dart';
import '../../widgets/ad_card.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/category_chips.dart';
import '../../widgets/deadline_badge.dart';
import '../../widgets/featured_card.dart';
import '../../widgets/filter_sheet.dart';
import '../../widgets/poster_image.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import '../details/details_screen.dart';

/// Discovery feed: branded header with greeting, live search, featured hero,
/// closing-soon rail, category filters and the latest advertisements list.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.service,
    required this.bookmarks,
    required this.themeController,
    this.onOpenSaved,
  });

  final AdvertisementService service;
  final BookmarkService bookmarks;
  final ThemeController themeController;
  final VoidCallback? onOpenSaved;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _category = AppConstants.allCategoriesId;
  FeedSortMode _sort = FeedSortMode.latest;
  bool _closingSoonOnly = false;
  String _query = '';
  late Future<List<Advertisement>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchPublished();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        builder: (_) => DetailsScreen(ad: ad, bookmarks: widget.bookmarks),
      ),
    );
  }

  Future<void> _openFilterSheet() async {
    final result = await showFeedFilterSheet(
      context,
      initial: FeedFilter(
        category: _category,
        sort: _sort,
        closingSoonOnly: _closingSoonOnly,
      ),
    );
    if (result != null) {
      setState(() {
        _category = result.category;
        _sort = result.sort;
        _closingSoonOnly = result.closingSoonOnly;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _category = AppConstants.allCategoriesId;
      _sort = FeedSortMode.latest;
      _closingSoonOnly = false;
      _query = '';
      _searchController.clear();
    });
  }

  bool get _hasActiveFilters =>
      _category != AppConstants.allCategoriesId ||
      _sort != FeedSortMode.latest ||
      _closingSoonOnly ||
      _query.trim().isNotEmpty;

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

    Advertisement? featured;
    for (final ad in active) {
      if (ad.isFeatured) {
        featured = ad;
        break;
      }
    }

    final closingSoon =
        sortFeedAds(active, FeedSortMode.nearestDeadline, now: now).where((ad) {
          final daysLeft = getDeadlineInfo(
            lastDate: ad.lastDate,
            now: now,
          ).daysLeft;
          return daysLeft != null &&
              daysLeft >= 0 &&
              daysLeft <= 7 &&
              ad.id != featured?.id;
        }).toList();

    var latest = active;
    if (_closingSoonOnly) {
      latest = latest.where((ad) {
        final daysLeft = getDeadlineInfo(
          lastDate: ad.lastDate,
          now: now,
        ).daysLeft;
        return daysLeft != null && daysLeft >= 0 && daysLeft <= 7;
      }).toList();
    }
    latest = filterByCategory(latest, _category);
    final query = _query.trim().toLowerCase();
    if (query.isNotEmpty) {
      latest = latest
          .where(
            (ad) =>
                ad.title.toLowerCase().contains(query) ||
                ad.organization.toLowerCase().contains(query),
          )
          .toList();
    }
    if (featured != null) {
      final featuredId = featured.id;
      latest = latest.where((ad) => ad.id != featuredId).toList();
    }
    latest = sortFeedAds(latest, _sort, now: now);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _topBar(context)),
        SliverToBoxAdapter(child: _greeting(context)),
        SliverToBoxAdapter(child: _searchRow(context)),
        if (featured != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
          SliverToBoxAdapter(child: _closingSoonRail(closingSoon)),
        ],
        SliverToBoxAdapter(
          child: CategoryChips(
            selected: _category,
            onSelected: (id) => setState(() => _category = id),
          ),
        ),
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Latest advertisements',
            icon: Icons.fiber_new_outlined,
            trailing: _countBadge(latest.length),
          ),
        ),
        if (latest.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EmptyView(
                  icon: Icons.search_off_outlined,
                  title: 'No advertisements found',
                  message: 'Try a different search term or category.',
                ),
                if (_hasActiveFilters)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TextButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: const Text('Reset filters'),
                    ),
                  ),
              ],
            ),
          )
        else
          _adsSliver(latest),
      ],
    );
  }

  Widget _topBar(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          const BrandLogo(height: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppConstants.brandName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(AppConstants.appName, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          _savedButton(),
          const SizedBox(width: 4),
          _themeButton(),
        ],
      ),
    );
  }

  Widget _savedButton() {
    return AnimatedBuilder(
      animation: widget.bookmarks,
      builder: (context, _) {
        final count = widget.bookmarks.ids.length;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.bookmark_border),
              tooltip: 'Saved advertisements',
              onPressed: widget.onOpenSaved,
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: BrandColors.mint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: BrandColors.nightBlack,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _themeButton() {
    return AnimatedBuilder(
      animation: widget.themeController,
      builder: (context, _) {
        final isDark = widget.themeController.isDark;
        return IconButton(
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          tooltip: isDark ? 'Switch to light mode' : 'Switch to night mode',
          onPressed: widget.themeController.toggle,
        );
      },
    );
  }

  Widget _greeting(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assalam-o-Alaikum 👋',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Find your next opportunity',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search advertisements…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: BrandColors.mint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: BrandColors.nightBlack),
              tooltip: 'Filter advertisements',
              onPressed: _openFilterSheet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _countBadge(int count) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: dark
            ? BrandColors.mint.withValues(alpha: 0.16)
            : BrandColors.mint.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: dark ? BrandColors.mint : BrandColors.mintDark,
        ),
      ),
    );
  }

  Widget _closingSoonRail(List<Advertisement> ads) {
    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const PageScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ads.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final ad = ads[index];
          return SizedBox(
            width: 280,
            child: _RailCard(ad: ad, onTap: () => _openDetails(ad)),
          );
        },
      ),
    );
  }

  Widget _adsSliver(List<Advertisement> ads) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        if (constraints.crossAxisExtent > 700) {
          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final ad = ads[index];
                return AdCard(
                  ad: ad,
                  bookmarks: widget.bookmarks,
                  onTap: () => _openDetails(ad),
                );
              }, childCount: ads.length),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 420,
                mainAxisExtent: 224,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final ad = ads[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AdCard(
                  ad: ad,
                  bookmarks: widget.bookmarks,
                  onTap: () => _openDetails(ad),
                ),
              );
            }, childCount: ads.length),
          ),
        );
      },
    );
  }
}

/// Compact card used in the "Closing soon" horizontal rail.
class _RailCard extends StatelessWidget {
  const _RailCard({required this.ad, required this.onTap});

  final Advertisement ad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = getDeadlineInfo(
      lastDate: ad.lastDate,
      publishedAt: ad.publishedAt,
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              PosterImage(
                url: ad.posterUrl,
                width: 72,
                height: 72,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      ad.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ad.organization,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    DeadlineBadge(info: info, compact: true),
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
