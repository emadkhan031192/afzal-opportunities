import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n/app_localizations.dart';
import '../models/carousel_slide.dart';

/// Auto-sliding welcome carousel (4 seconds).
///
/// Shows the built-in English + Urdu welcome slides (text only, no badge).
/// Fully self-contained — no admin panel, no Firestore.
class WelcomeCarousel extends StatefulWidget {
  const WelcomeCarousel({super.key, this.teaching = false});

  final bool teaching;

  @override
  State<WelcomeCarousel> createState() => _WelcomeCarouselState();
}

class _WelcomeCarouselState extends State<WelcomeCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _index = 0;
  late final List<CarouselSlide> _slides;

  @override
  void initState() {
    super.initState();
    _slides = _buildSlides();
    // 4-second auto-slide over the actually displayed slides.
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_slides.length < 2) return;
      final next = (_index + 1) % _slides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  List<CarouselSlide> _buildSlides() {
    final en = AppLocalizations(const Locale('en'));
    final ur = AppLocalizations(const Locale('ur'));
    if (widget.teaching) {
      return [
        CarouselSlide(
          badge: '',
          title: en.carouselTeachingTitle,
          desc: en.carouselTeachingDesc,
          rtl: false,
        ),
        CarouselSlide(
          badge: '',
          title: ur.carouselTeachingTitle,
          desc: ur.carouselTeachingDesc,
          rtl: true,
        ),
      ];
    }
    return [
      CarouselSlide(
        badge: '',
        title: en.carouselHomeTitle,
        desc: en.carouselHomeDesc,
        rtl: false,
      ),
      CarouselSlide(
        badge: '',
        title: ur.carouselHomeTitle,
        desc: ur.carouselHomeDesc,
        rtl: true,
      ),
    ];
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final slide = _slides[i];
              return Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 36),
                child: Column(
                  crossAxisAlignment: slide.rtl
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                _slides.length,
                (i) => GestureDetector(
                  onTap: () => _controller.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _index == i
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
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
