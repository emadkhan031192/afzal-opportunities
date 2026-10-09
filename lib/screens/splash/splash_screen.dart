import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/brand_colors.dart';

/// Splash / onboarding screen recreating the user's designed Page 1:
/// lavender background, white rounded card, brand wordmark, tagline,
/// paper-plane accent and the circle "A" app icon as the central visual.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2600), _finish);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _finish() {
    if (_gone) return;
    _gone = true;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.splashBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: GestureDetector(
            onTap: _finish,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(
                  children: [
                    // Paper plane accent, top-right.
                    const Positioned(
                      top: 18,
                      right: 26,
                      child: _PaperPlane(size: 72),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(26, 30, 26, 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Wordmark.
                          const Text(
                            'AFZAL',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: BrandColors.splashPurple,
                            ),
                          ),
                          const Text(
                            'E SERVICES',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: BrandColors.nightBlue,
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Tagline.
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 21,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                                color: BrandColors.nightBlue,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '${AppLocalizations.of(context).taglineA1}\n',
                                ),
                                TextSpan(
                                  text:
                                      '${AppLocalizations.of(context).taglineA2} ',
                                  style: const TextStyle(
                                    color: BrandColors.splashPurple,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '${AppLocalizations.of(context).taglineB1}\n${AppLocalizations.of(context).taglineB2}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Central visual: the circle "A" app icon on a
                          // periwinkle band, echoing the mockup's diagonal
                          // stripe behind the photo.
                          Expanded(
                            child: Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.rotate(
                                    angle: -0.22,
                                    child: Container(
                                      width: 260,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: BrandColors.splashPurple,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 132,
                                    height: 132,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.18,
                                          ),
                                          blurRadius: 18,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/icon/app_icon.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Get-started pill, echoing the mockup's bottom
                          // pill (check — chevrons — check).
                          Center(
                            child: GestureDetector(
                              onTap: _finish,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: BrandColors.splashBackground,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        color: BrandColors.splashPurple,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context).getStarted,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: BrandColors.nightBlue,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: BrandColors.mutedOnLight,
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: BrandColors.mutedOnLight,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple paper-plane outline accent drawn like the mockup's plane graphic.
class _PaperPlane extends StatelessWidget {
  const _PaperPlane({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _PaperPlanePainter());
  }
}

class _PaperPlanePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BrandColors.splashPurple
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.55)
      ..lineTo(size.width * 0.9, size.height * 0.1)
      ..lineTo(size.width * 0.62, size.height * 0.92)
      ..lineTo(size.width * 0.5, size.height * 0.58)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
