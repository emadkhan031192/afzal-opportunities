import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/l10n/app_localizations.dart';
import '../core/theme/brand_colors.dart';
import '../core/utils/feed_sort.dart';

/// Feed filter state chosen in the filter bottom sheet.
class FeedFilter {
  const FeedFilter({
    required this.category,
    required this.sort,
    required this.closingSoonOnly,
  });

  final String category;
  final FeedSortMode sort;
  final bool closingSoonOnly;
}

/// Opens the filter bottom sheet and returns the chosen filter,
/// or null when dismissed without applying.
Future<FeedFilter?> showFeedFilterSheet(
  BuildContext context, {
  required FeedFilter initial,
}) {
  return showModalBottomSheet<FeedFilter>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _FilterSheet(initial: initial),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final FeedFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _category;
  late FeedSortMode _sort;
  late bool _closingSoonOnly;

  @override
  void initState() {
    super.initState();
    _category = widget.initial.category;
    _sort = widget.initial.sort;
    _closingSoonOnly = widget.initial.closingSoonOnly;
  }

  void _reset() {
    setState(() {
      _category = AppConstants.allCategoriesId;
      _sort = FeedSortMode.latest;
      _closingSoonOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(s.filter, style: theme.textTheme.titleLarge),
                const Spacer(),
                TextButton(onPressed: _reset, child: Text(s.reset)),
              ],
            ),
            const SizedBox(height: 8),
            Text(s.category, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _categoryChip(AppConstants.allCategoriesId, s.all),
                for (final category in AppConstants.categories)
                  _categoryChip(category.id, _categoryLabel(category.id, s)),
              ],
            ),
            const SizedBox(height: 16),
            Text(s.sortBy, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<FeedSortMode>(
              segments: [
                ButtonSegment(
                  value: FeedSortMode.latest,
                  label: Text(s.latest),
                  icon: const Icon(Icons.fiber_new_outlined),
                ),
                ButtonSegment(
                  value: FeedSortMode.nearestDeadline,
                  label: Text(s.deadline),
                  icon: const Icon(Icons.schedule_outlined),
                ),
                ButtonSegment(
                  value: FeedSortMode.relevance,
                  label: Text(s.relevance),
                  icon: const Icon(Icons.auto_awesome_outlined),
                ),
              ],
              selected: {_sort},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                setState(() => _sort = selection.first);
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _closingSoonOnly,
              onChanged: (value) => setState(() => _closingSoonOnly = value),
              title: Text(s.closingSoonOnly),
              subtitle: Text(s.closingSoonHint),
              activeThumbColor: BrandColors.mint,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(
                FeedFilter(
                  category: _category,
                  sort: _sort,
                  closingSoonOnly: _closingSoonOnly,
                ),
              ),
              child: Text(s.applyFilters),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String id, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _category == id,
      onSelected: (_) => setState(() => _category = id),
    );
  }

  String _categoryLabel(String id, AppLocalizations s) {
    switch (id) {
      case 'jobs':
        return s.jobs;
      case 'scholarships':
        return s.scholarships;
      case 'admissions':
        return s.admissions;
      case 'other':
      default:
        return s.other;
    }
  }
}
