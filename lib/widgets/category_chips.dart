import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

/// Horizontal category filter chips: All + the four v1.0 categories.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <_ChipItem>[
      const _ChipItem(AppConstants.allCategoriesId, 'All'),
      for (final category in AppConstants.categories)
        _ChipItem(category.id, category.label),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          separatorBuilder: (context, index) =>
              const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return ChoiceChip(
              label: Text(item.label),
              selected: item.id == selected,
              onSelected: (_) => onSelected(item.id),
            );
          },
        ),
      ),
    );
  }
}

class _ChipItem {
  const _ChipItem(this.id, this.label);

  final String id;
  final String label;
}
