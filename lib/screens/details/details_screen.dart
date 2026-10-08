import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/utils/deadline.dart';
import '../../core/utils/url_utils.dart';
import '../../models/advertisement.dart';
import '../../services/bookmark_service.dart';
import '../../widgets/deadline_badge.dart';
import '../../widgets/poster_image.dart';

/// Full advertisement view: poster hero, headline, stat cards, urgency
/// banner, description and official links opened safely in an external
/// browser, with a sticky action bar.
class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key, required this.ad, required this.bookmarks});

  final Advertisement ad;
  final BookmarkService bookmarks;

  Future<void> _openLink(
    BuildContext context,
    String? url,
    String label,
  ) async {
    final opened = await openUrl(url);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the $label link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = getDeadlineInfo(
      lastDate: ad.lastDate,
      publishedAt: ad.publishedAt,
    );
    final dateFormat = DateFormat('d MMM yyyy');
    final hasPoster = (ad.posterUrl ?? '').trim().isNotEmpty;
    final hasSource = isSafeHttpUrl(ad.sourceUrl);
    final hasApplication = isSafeHttpUrl(ad.applicationUrl);
    final daysLeft = info.daysLeft;
    final showUrgency = daysLeft != null && daysLeft >= 0 && daysLeft <= 7;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _hero(context, hasPoster),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CategoryPill(categoryId: ad.category),
                      const SizedBox(width: 8),
                      Expanded(child: DeadlineBadge(info: info)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(ad.title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ad.organization,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _statRow(context, dateFormat),
                  if (showUrgency) ...[
                    const SizedBox(height: 12),
                    _urgencyBanner(context, info, daysLeft),
                  ],
                  const SizedBox(height: 24),
                  Text('Description', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(ad.description, style: theme.textTheme.bodyLarge),
                  if (hasSource || hasApplication) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Official information',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'The links below come directly from the advertising '
                      'organization.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    if (hasApplication)
                      _linkTile(
                        context,
                        icon: Icons.open_in_new,
                        title: 'Application portal',
                        subtitle: _host(ad.applicationUrl),
                        onTap: () => _openLink(
                          context,
                          ad.applicationUrl,
                          'application',
                        ),
                      ),
                    if (hasSource)
                      _linkTile(
                        context,
                        icon: Icons.link,
                        title: 'Official source',
                        subtitle: _host(ad.sourceUrl),
                        onTap: () => _openLink(context, ad.sourceUrl, 'source'),
                      ),
                  ],
                  const SizedBox(height: 24),
                  _disclaimer(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: (hasSource || hasApplication)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    if (hasSource)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _openLink(context, ad.sourceUrl, 'source'),
                          icon: const Icon(Icons.link),
                          label: const Text('Official Source'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: BrandColors.mockupBlue,
                            side: const BorderSide(
                              color: BrandColors.mockupBlue,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    if (hasSource && hasApplication) const SizedBox(width: 12),
                    if (hasApplication)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openLink(
                            context,
                            ad.applicationUrl,
                            'application',
                          ),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Apply Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BrandColors.mockupBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  /// Poster hero with overlaid back and bookmark buttons, or a branded
  /// gradient placeholder when the advertisement has no poster.
  Widget _hero(BuildContext context, bool hasPoster) {
    final topPadding = MediaQuery.of(context).padding.top + 8;
    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasPoster)
            PosterImage(url: ad.posterUrl, borderRadius: BorderRadius.zero)
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [BrandColors.mockupBlue, BrandColors.nightBlue],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.campaign_outlined,
                  size: 72,
                  color: Colors.white,
                ),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66000000), Colors.transparent],
              ),
            ),
          ),
          Positioned(
            top: topPadding,
            left: 12,
            child: _circleButton(
              icon: Icons.arrow_back,
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            top: topPadding,
            right: 12,
            child: AnimatedBuilder(
              animation: bookmarks,
              builder: (context, _) {
                final saved = bookmarks.isBookmarked(ad.id);
                return _circleButton(
                  icon: saved ? Icons.bookmark : Icons.bookmark_border,
                  tooltip: saved ? 'Remove bookmark' : 'Save advertisement',
                  color: saved ? BrandColors.mint : BrandColors.nightBlack,
                  onPressed: () => bookmarks.toggle(ad.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color color = BrandColors.nightBlack,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _statRow(BuildContext context, DateFormat dateFormat) {
    final location = (ad.location ?? '').trim();
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.event_outlined,
            label: 'Last Date',
            value: ad.lastDate != null
                ? dateFormat.format(ad.lastDate!)
                : 'Not specified',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: location.isEmpty ? '—' : location,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.category_outlined,
            label: 'Category',
            value: AppConstants.categoryLabel(ad.category),
          ),
        ),
      ],
    );
  }

  Widget _urgencyBanner(BuildContext context, DeadlineInfo info, int daysLeft) {
    final urgent = daysLeft <= 1;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: urgent ? BrandColors.dangerTint : BrandColors.amberTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            color: urgent ? BrandColors.dangerStrong : BrandColors.amberStrong,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: urgent
                        ? BrandColors.dangerStrong
                        : BrandColors.amberStrong,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Apply before the last date.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: urgent
                        ? BrandColors.dangerStrong
                        : BrandColors.amberStrong,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  String _host(String? url) {
    final host = Uri.tryParse((url ?? '').trim())?.host ?? '';
    return host.isEmpty ? 'Official website' : host;
  }

  Widget _disclaimer(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark
            ? BrandColors.mint.withValues(alpha: 0.1)
            : BrandColors.mint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'The description above was entered by the ${AppConstants.brandName} '
              'administrator. Always verify details on the official source '
              'before applying.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small stat card used in the details stat row.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(label.toUpperCase(), style: theme.textTheme.labelSmall),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
