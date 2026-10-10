import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n/app_localizations.dart';
import '../models/carousel_slide.dart';
import '../services/carousel_service.dart';

/// Auto-sliding welcome carousel.
///
/// Slides come from Firestore (`carouselSlides` collection, managed in the
/// admin panel) and fall back to hardcoded EN/UR defaults when unavailable.
/// One slide is always English, one always Urdu — independent of the app's
/// current locale, as the user requested.
class WelcomeCarousel extends StatefulWidget {
  const WelcomeCarousel({super.key, this.teaching = false});

  final bool teaching;

  @override
  State<WelcomeCarousel> createState() => _WelcomeCarouselState();
}

class _WelcomeCarouselState extends State<WelcomeCarousel> {
  final PageController _controller = PageController();
  final CarouselService _service = CarouselService();
  Timer? _timer;
  int _index = 0;
  List<CarouselSlide>? _slides;

  @override
  void initState() {
    super.initState();
    _loadSlides();
    // Slower auto-slide (6s) so text can be read.
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      final count = (_slides ?? []).length;
      if (count < 2) return;
      final next = (_index + 1) % count;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _loadSlides() async {
    final slides = await _service.getSlides(teaching: widget.teaching);
    if (mounted) {
      setState(() => _slides = slides.isEmpty ? null : slides);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  List<CarouselSlide> _displaySlides(AppLocalizations ur) {
    if (_slides != null) return _slides!;
    return [
      CarouselSlide(
        badge: widget.teaching ? 'Private Education' : 'Welcome',
        title: widget.teaching
            ? 'Private School & Academy Vacancies'
            : 'Welcome to Afzal-E Services',
        desc: widget.teaching
            ? 'Exclusive portal for private schools and academies to post teaching vacancies, and for qualified teachers to find jobs.'
            : 'Your trusted hub for verified job alerts, scholarships, and career opportunities across Pakistan.',
        rtl: false,
      ),
      CarouselSlide(
        badge: widget.teaching
            ? ur.carouselTeachingBadge
            : ur.carouselHomeBadge,
        title: widget.teaching
            ? ur.carouselTeachingTitle
            : ur.carouselHomeTitle,
        desc: widget.teaching ? ur.carouselTeachingDesc : ur.carouselHomeDesc,
        rtl: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ur = AppLocalizations(const Locale('ur'));
    final displaySlides = _displaySlides(ur);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      // Taller to fit 3 lines of description without cutting.
      height: 178,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.teaching
              ? const [Color(0xFF065F46), Color(0xFF047857)]
              : const [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: displaySlides.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final slide = displaySlides[i];
              return Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 36),
                child: Column(
                  crossAxisAlignment: slide.rtl
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        slide.badge.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      slide.title,
                      textAlign: slide.rtl ? TextAlign.right : TextAlign.left,
                      textDirection: slide.rtl
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      slide.desc,
                      textAlign: slide.rtl ? TextAlign.right : TextAlign.left,
                      textDirection: slide.rtl
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFCBD5E1),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 12,
            right: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                displaySlides.length,
                (i) => GestureDetector(
                  onTap: () => _controller.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    width: _index == i ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _index == i
                          ? const Color(0xFF10B981)
                          : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
