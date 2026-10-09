import 'package:flutter/material.dart';

import 'brand_colors.dart';

/// Category-tinted card palette for the v1.3.0 redesign.
///
/// Replaces the v1.2.0 position-based pastel alternation: card color now
/// signals the advertisement category at a glance (Jobs blue, Scholarships
/// mint, Admissions amber, Other rose), with deep-navy variants for dark
/// mode so the pastel system stays readable at night.
class CardTint {
  const CardTint({
    required this.background,
    required this.ink,
    required this.subInk,
    required this.chip,
  });

  /// Card background.
  final Color background;

  /// Primary text on the card.
  final Color ink;

  /// Secondary text on the card.
  final Color subInk;

  /// Category chip background on the card.
  final Color chip;
}

/// Returns the card tint for an advertisement category id.
CardTint cardTintForCategory(String categoryId, bool dark) {
  switch (categoryId) {
    case 'scholarships':
      return dark
          ? const CardTint(
              background: Color(0xFF1E4D3A),
              ink: Colors.white,
              subInk: Color(0xFFB9D9C8),
              chip: Color(0xFF2E6B4F),
            )
          : const CardTint(
              background: Color(0xFFB9E8CF),
              ink: BrandColors.nightBlue,
              subInk: Color(0xFF3E5A4C),
              chip: Color(0xFF8FD3AC),
            );
    case 'admissions':
      return dark
          ? const CardTint(
              background: Color(0xFF6B5416),
              ink: Colors.white,
              subInk: Color(0xFFE8D5A0),
              chip: Color(0xFF8A6D1F),
            )
          : const CardTint(
              background: BrandColors.cardYellow,
              ink: BrandColors.nightBlue,
              subInk: Color(0xFF6B5A1E),
              chip: Color(0xFFF0BE4A),
            );
    case 'other':
      return dark
          ? const CardTint(
              background: Color(0xFF6B3537),
              ink: Colors.white,
              subInk: Color(0xFFE8B9BB),
              chip: BrandColors.cardPinkDark,
            )
          : const CardTint(
              background: BrandColors.cardPink,
              ink: Colors.white,
              subInk: Color(0xFFF6D9DA),
              chip: BrandColors.cardPinkDark,
            );
    case 'jobs':
    default:
      return dark
          ? const CardTint(
              background: Color(0xFF1B3A6B),
              ink: Colors.white,
              subInk: Color(0xFFB9CBE8),
              chip: Color(0xFF2B4F86),
            )
          : const CardTint(
              background: BrandColors.mockupBlue,
              ink: Colors.white,
              subInk: Color(0xFFD6E4FA),
              chip: Color(0xFF3E7FDB),
            );
  }
}
