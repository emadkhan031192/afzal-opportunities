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
import '../../widgets/app_header.dart';
import '../../widgets/category_chips.dart';
import '../../widgets/filter_sheet.dart';
import '../../widgets/home_greeting.dart';
import '../../widgets/notification_inbox_sheet.dart';
import '../../widgets/settings_sheet.dart';
import '../../widgets/state_views.dart';
import '../../widgets/vibrant_ad_card.dart';
import '../../widgets/welcome_carousel.dart';
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
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchPublished();
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    final count = await widget.notificationService.getUnreadCount();
    if (mounted) setState(() => _unreadCount = count);
  }

  Future<void> _openInbox() async {
    await NotificationInboxSheet.show(context, widget.notificationService);
    await _loadUnread();
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
          child: AppHeader(
            onOpenSettings: () => SettingsSheet.show(
              context,
              themeController: widget.themeController,
              localeController: widget.localeController,
              notificationService: widget.notificationService,
            ),
            onOpenNotifications: _openInbox,
            hasUnreadNotifications: _unreadCount > 0,
          ),
        ),
        const SliverToBoxAdapter(child: WelcomeCarousel()),
        const SliverToBoxAdapter(child: HomeGreeting()),
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

  /// Compact search + filter row kept under the carousel so discovery tools
  /// stay one tap away without disturbing the layout.
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

  /// Section header: "Latest Advertisements" with the List/Grid toggle
  /// from the user's final UI.
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
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: dark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToggleButton(
                  label: '☰ ${s.listView}',
                  active: !_gridView,
                  onTap: () => setState(() => _gridView = false),
                ),
                _ToggleButton(
                  label: '⊞ ${s.gridView}',
                  active: _gridView,
                  onTap: () => setState(() => _gridView = true),
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final ad = ads[index];
          return AnimatedBuilder(
            animation: widget.bookmarks,
            builder: (context, _) => VibrantAdCard(
              ad: ad,
              index: index,
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) {
          final ad = ads[index];
          return AnimatedBuilder(
            animation: widget.bookmarks,
            builder: (context, _) => VibrantAdCard(
              ad: ad,
              index: index,
              isSaved: widget.bookmarks.isBookmarked(ad.id),
              onTap: () => _openDetails(ad),
              onToggleSave: () => widget.bookmarks.toggle(ad.id),
            ),
          );
        }, childCount: ads.length),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.58,
        ),
      ),
    );
  }
}

/// Toggle button for the List/Grid view switch.
class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? (dark ? Colors.white.withValues(alpha: 0.12) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active
                ? (dark ? Colors.white : const Color(0xFF0F172A))
                : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
