import 'package:flutter/material.dart';

/// Afzal E Services brand palette (extracted from the official logo).
class BrandColors {
  const BrandColors._();

  /// Night navy — primary brand surface.
  static const Color nightBlue = Color(0xFF1C1B2E);

  /// Night black — darkest app background.
  static const Color nightBlack = Color(0xFF0C0E24);

  /// Mint green — highlights, labels and primary actions.
  static const Color mint = Color(0xFF5ABF93);

  /// Darker mint, derived from [mint] for accessible contrast on white
  /// surfaces (light-theme accents, text on light backgrounds).
  static const Color mintDark = Color(0xFF3E8F6B);

  /// White — primary text on dark surfaces.
  static const Color white = Color(0xFFFFFFFF);

  /// Light background — light-mode card surfaces.
  static const Color lightBackground = Color(0xFFF4F6F8);

  /// Muted text — secondary text on dark surfaces.
  static const Color muted = Color(0xFF8A90A6);

  /// Muted text tuned for light surfaces (stronger contrast).
  static const Color mutedOnLight = Color(0xFF5A6076);

  /// Amber tint used for "closing soon" deadline badges.
  static const Color amberTint = Color(0xFFFFF4E0);

  /// Amber foreground used for "closing soon" deadline badges.
  static const Color amberStrong = Color(0xFF8A5A00);

  /// Red tint used for urgent/expired deadline badges.
  static const Color dangerTint = Color(0xFFFDECEA);

  /// Red foreground used for urgent/expired deadline badges.
  static const Color dangerStrong = Color(0xFFC62828);
}
