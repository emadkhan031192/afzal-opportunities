import 'package:flutter/material.dart';

/// The Afzal E Services logo inside a white rounded container.
///
/// The logo artwork is dark navy, so it is always presented on a white
/// background to stay visible in both night and light themes.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.height = 40,
    this.borderRadius = 12,
    this.padding = 8,
  });

  final double height;
  final double borderRadius;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Image.asset(
        'assets/logo/afzal_e_services_logo.png',
        height: height,
        fit: BoxFit.contain,
        semanticLabel: 'Afzal E Services logo',
      ),
    );
  }
}
