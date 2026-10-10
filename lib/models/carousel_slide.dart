/// Carousel slide data model.
class CarouselSlide {
  const CarouselSlide({
    required this.badge,
    required this.title,
    required this.desc,
    required this.rtl,
    this.order = 0,
    this.active = true,
  });

  final String badge;
  final String title;
  final String desc;
  final bool rtl;
  final int order;
  final bool active;

  factory CarouselSlide.fromJson(String id, Map<String, dynamic> json) {
    String str(String key) {
      final v = json[key];
      return v is String ? v : '';
    }

    int num(String key) {
      final v = json[key];
      if (v is int) return v;
      if (v is double) return v.toInt();
      return 0;
    }

    return CarouselSlide(
      badge: str('badge'),
      title: str('title'),
      desc: str('desc'),
      rtl: json['rtl'] is bool ? json['rtl'] as bool : false,
      order: num('order'),
      active: json['active'] is bool ? (json['active'] as bool) : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'badge': badge,
      'title': title,
      'desc': desc,
      'rtl': rtl,
      'order': order,
      'active': active,
    };
  }
}
