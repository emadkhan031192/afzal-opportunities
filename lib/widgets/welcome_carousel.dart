import 'dart:async';

import 'package:flutter/material.dart';

import '../models/carousel_slide.dart';
import '../services/carousel_service.dart';

/// Auto-sliding welcome carousel.
///
/// Slides come from Firestore (`carouselSlides` collection, managed in the
/// admin panel). When no slides exist yet, the carousel hides itself
/// instead of showing placeholder content.
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
      setState(() => _slides = slides);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;
    // Still loading: reserve no space yet. No slides: hide the carousel
    // entirely instead of showing placeholder content.
    if (slides == null || slides.isEmpty) {
      return const SizedBox.shrink();
    }

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
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final slide = slides[i];
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
                slides.length,
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
