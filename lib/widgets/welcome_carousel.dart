import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n/app_localizations.dart';

/// Auto-sliding welcome carousel from the user's final UI: EN/UR slides
/// with a badge, title, description and dot indicators. The [teaching]
/// variant uses the green teaching gradient; otherwise the dark navy
/// home gradient.
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

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_index + 1) % 2;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    // Always show both EN and UR slides regardless of current locale,
    // matching the HTML design.
    final displaySlides = <_SlideData>[
      _SlideData(
        badge: widget.teaching ? 'Private Education' : 'Welcome',
        title: widget.teaching
            ? 'Private School & Academy Vacancies'
            : 'Welcome to Afzal-E Services',
        desc: widget.teaching
            ? 'Exclusive portal for private schools and academies to post teaching vacancies, and for qualified teachers to find jobs.'
            : 'Your trusted hub for verified job alerts, scholarships, and career opportunities across Pakistan.',
        rtl: false,
      ),
      _SlideData(
        badge: s.carouselTeachingBadge.isNotEmpty && widget.teaching
            ? s.carouselTeachingBadge
            : s.carouselHomeBadge,
        title: widget.teaching ? s.carouselTeachingTitle : s.carouselHomeTitle,
        desc: widget.teaching ? s.carouselTeachingDesc : s.carouselHomeDesc,
        rtl: true,
      ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      height: 150,
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
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 34),
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
                      maxLines: 2,
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

class _SlideData {
  const _SlideData({
    required this.badge,
    required this.title,
    required this.desc,
    required this.rtl,
  });

  final String badge;
  final String title;
  final String desc;
  final bool rtl;
}
