import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme/brand_colors.dart';

/// App header from the user's mockups: the "A" mark SVG beside the
/// "AFZAL-E SERVICES" wordmark (mint "-E"), with the active section title
/// ("Jobs", "Scholarships", …) on the right.
class MockupHeader extends StatelessWidget {
  const MockupHeader({super.key, required this.sectionTitle});

  final String sectionTitle;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : BrandColors.nightBlue;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/logo/a_mark.svg',
          height: 44,
          colorFilter: dark
              ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
              : null,
        ),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: ink,
              height: 1.1,
            ),
            children: const [
              TextSpan(text: 'AFZAL-'),
              TextSpan(
                text: 'E',
                style: TextStyle(color: BrandColors.mint),
              ),
              TextSpan(text: '\nSERVICES'),
            ],
          ),
        ),
        const Spacer(),
        Text(
          sectionTitle,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: ink,
          ),
        ),
      ],
    );
  }
}
