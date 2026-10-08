import 'package:flutter/material.dart';

import '../../models/advertisement.dart';
import '../../services/advertisement_service.dart';
import '../../services/bookmark_service.dart';
import '../../widgets/ad_card.dart';
import '../../widgets/state_views.dart';
import '../details/details_screen.dart';

/// Bookmarked advertisements. Expired items stay visible here with a clear
/// EXPIRED badge instead of disappearing like they do in the main feed.
class SavedScreen extends StatefulWidget {
  const SavedScreen({
    super.key,
    required this.service,
    required this.bookmarks,
    this.onBrowse,
  });

  final AdvertisementService service;
  final BookmarkService bookmarks;
  final VoidCallback? onBrowse;

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
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
        builder: (_) => DetailsScreen(ad: ad, bookmarks: widget.bookmarks),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: widget.bookmarks,
      builder: (context, _) {
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
                      'Could not load saved advertisements. Check your connection and try again.',
                  onRetry: _refresh,
                );
              }
              final saved = (snapshot.data ?? <Advertisement>[])
                  .where((ad) => widget.bookmarks.isBookmarked(ad.id))
                  .toList();
              if (saved.isEmpty) {
                return ListView(
                  children: [
                    const SizedBox(height: 80),
                    const EmptyView(
                      icon: Icons.bookmark_border,
                      title: 'No saved advertisements',
                      message:
                          'Tap the bookmark icon on any advertisement to save it here.',
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: ElevatedButton.icon(
                          onPressed: widget.onBrowse,
                          icon: const Icon(Icons.explore_outlined),
                          label: const Text('Browse advertisements'),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saved',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${saved.length} saved advertisement${saved.length == 1 ? '' : 's'}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final ad = saved[index];
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          index == 0 ? 12 : 0,
                          16,
                          12,
                        ),
                        child: AdCard(
                          ad: ad,
                          bookmarks: widget.bookmarks,
                          onTap: () => _openDetails(ad),
                        ),
                      );
                    }, childCount: saved.length),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
