import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/deadline.dart';
import '../../core/utils/feed_sort.dart';
import '../../models/advertisement.dart';
import '../../services/advertisement_service.dart';
import '../../services/bookmark_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/category_chips.dart';
import '../../widgets/filter_sheet.dart';
import '../../widgets/job_grid_card.dart';
import '../../widgets/job_list_card.dart';
import '../../widgets/mockup_header.dart';
import '../../widgets/settings_sheet.dart';
import '../../widgets/state_views.dart';
import '../details/details_screen.dart';

/// Discovery feed rebuilt from the user's designed Pages 2–4:
/// brand header, "Latest advertisements" pills with a list/grid toggle,
/// category chips, a closing-soon section and alternating pastel cards.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.service,
    required this.bookmarks,
    required this.themeController,
    required this.localeController,
    required this.notificationService,
    this.onOpenSaved,
  });

  final AdvertisementService service;
  final BookmarkService bookmarks;
  final ThemeController themeController;
  final LocaleController localeController;
  final NotificationService notificationService;
  final VoidCallback? onOpenSaved;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _category = AppConstants.allCategoriesId;
  FeedSortMode _sort = FeedSortMode.latest;
  bool _closingSoonOnly = false;
  bool _gridView = false;
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

  String _sectionTitle(AppLocalizations s) {
    if (_category == AppConstants.allCategoriesId) return s.jobs;
    switch (_category) {
      case 'scholarships':
        return s.scholarships;
      case 'admissions':
        return s.admissions;
      case 'other':
        return s.other;
      default:
        return AppConstants.categoryLabel(_category);
    }
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
    var latest = filterActiveAds(all, now: now);

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
    latest = sortFeedAds(latest, _sort, now: now);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: MockupHeader(
              sectionTitle: _sectionTitle(AppLocalizations.of(context)),
              onOpenSettings: () => SettingsSheet.show(
                context,
                themeController: widget.themeController,
                localeController: widget.localeController,
                notificationService: widget.notificationService,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: _pillsRow()),
        SliverToBoxAdapter(child: _searchRow()),
        SliverToBoxAdapter(
          child: CategoryChips(
            selected: _category,
            onSelected: (id) => setState(() => _category = id),
          ),
        ),
        SliverToBoxAdapter(child: _sectionHeader()),
        if (latest.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EmptyView(
                  icon: Icons.search_off_outlined,
                  title: AppLocalizations.of(context).noAdsFound,
                  message: AppLocalizations.of(context).noAdsFoundHint,
                ),
                if (_hasActiveFilters)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TextButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: Text(AppLocalizations.of(context).resetFilters),
                    ),
                  ),
              ],
            ),
          )
        else if (_gridView)
          _gridSliver(latest)
        else
          _listSliver(latest),
      ],
    );
  }

  /// Blue pills row: static "Latest advertisements" label + tappable
  /// list/grid view toggle, as in the mockups.
  Widget _pillsRow() {
    final s = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Row(
        children: [
          _Pill(label: s.latestAdvertisements, onTap: null),
          const SizedBox(width: 10),
          _Pill(
            label: _gridView ? s.gridView : s.listView,
            onTap: () => setState(() => _gridView = !_gridView),
          ),
        ],
      ),
    );
  }

  /// Compact search + filter row kept under the pills so discovery tools
  /// stay one tap away without disturbing the mockup layout.
  Widget _searchRow() {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final s = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: s.searchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  filled: true,
                  fillColor: dark
                      ? Colors.white.withValues(alpha: 0.07)
                      : BrandColors.lightBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: BrandColors.mockupBlue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: Colors.white, size: 20),
              tooltip: 'Filter advertisements',
              onPressed: _openFilterSheet,
            ),
          ),
        ],
      ),
    );
  }

  /// Section header: "Closing soon" with a "See all" toggle (the mockup's
  /// "Popular Agency" slot repurposed for the real closing-soon filter).
  Widget _sectionHeader() {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final s = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          Text(
            _closingSoonOnly ? s.closingSoon : s.latestAdvertisements,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: dark ? Colors.white : BrandColors.nightBlue,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _closingSoonOnly = !_closingSoonOnly),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_closingSoonOnly)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: BrandColors.mutedOnLight,
                    ),
                  ),
                Text(
                  s.seeAll,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: BrandColors.mutedOnLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _listSliver(List<Advertisement> ads) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final ad = ads[index];
          return AnimatedBuilder(
            animation: widget.bookmarks,
            builder: (context, _) => JobListCard(
              ad: ad,
              isSaved: widget.bookmarks.isBookmarked(ad.id),
              onTap: () => _openDetails(ad),
              onToggleSave: () => widget.bookmarks.toggle(ad.id),
            ),
          );
        }, childCount: ads.length),
      ),
    );
  }

  Widget _gridSliver(List<Advertisement> ads) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) {
          final ad = ads[index];
          return JobGridCard(ad: ad, onTap: () => _openDetails(ad));
        }, childCount: ads.length),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
      ),
    );
  }
}

/// Rounded blue pill used for the "Latest advertisements" label and the
/// list/grid view toggle.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      decoration: BoxDecoration(
        color: BrandColors.mockupBlue,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
    if (onTap == null) return pill;
    return GestureDetector(onTap: onTap, child: pill);
  }
}
