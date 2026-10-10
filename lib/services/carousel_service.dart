import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/carousel_slide.dart';
import 'firebase_config.dart';

/// Fetches welcome-carousel slides from Firestore.
///
/// Slides are managed in the admin panel (collection `carouselSlides`).
/// Returns an empty list when Firestore is unavailable or no active
/// slides exist — the carousel falls back to its hardcoded defaults.
class CarouselService {
  CarouselService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  bool get _ready => FirebaseConfig.isConfigured;

  Future<List<CarouselSlide>> getSlides({required bool teaching}) async {
    if (!_ready) return const [];
    try {
      final snapshot = await _db
          .collection('carouselSlides')
          .where('active', isEqualTo: true)
          .where('teaching', isEqualTo: teaching)
          .orderBy('order')
          .get();
      return snapshot.docs
          .map((d) {
            try {
              return CarouselSlide.fromJson(d.id, d.data());
            } catch (_) {
              return null;
            }
          })
          .whereType<CarouselSlide>()
          .where((s) => s.title.trim().isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Carousel slides fetch failed: $e');
      return const [];
    }
  }
}
