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

/// Full advertisement view: headline, poster, description, dates,
/// location and official links opened safely in an external browser.
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advertisement'),
        actions: [
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasPoster) PosterImage(url: ad.posterUrl, height: 220),
            Padding(
              padding: const EdgeInsets.all(20),
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
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ad.organization,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  if (ad.location != null && ad.location!.isNotEmpty)
                    _metaRow(
                      context,
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: ad.location!,
                    ),
                  if (ad.publishedAt != null)
                    _metaRow(
                      context,
                      icon: Icons.calendar_month_outlined,
                      label: 'Published',
                      value: dateFormat.format(ad.publishedAt!),
                    ),
                  _metaRow(
                    context,
                    icon: Icons.event_outlined,
                    label: 'Last date',
                    value: ad.lastDate != null
                        ? dateFormat.format(ad.lastDate!)
                        : 'Not specified',
                  ),
                  const SizedBox(height: 16),
                  Text('Description', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(ad.description, style: theme.textTheme.bodyLarge),
                  if (hasSource || hasApplication) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Official information',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (hasApplication)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openLink(
                              context,
                              ad.applicationUrl,
                              'application',
                            ),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Apply on official website'),
                          ),
                        ),
                      ),
                    if (hasSource)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _openLink(context, ad.sourceUrl, 'source'),
                          icon: const Icon(Icons.link),
                          label: const Text('Open official source'),
                        ),
                      ),
                  ],
                  const SizedBox(height: 24),
                  _disclaimer(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: theme.textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _disclaimer(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark
            ? BrandColors.mint.withValues(alpha: 0.1)
            : BrandColors.mint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
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
