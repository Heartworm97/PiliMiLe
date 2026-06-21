class DoubanSubject {
  final String id;
  final String title;
  final String picLarge;
  final String picNormal;
  final double ratingValue;
  final int ratingCount;
  final double starCount;
  final String cardSubtitle;
  final String type;

  DoubanSubject({
    required this.id,
    required this.title,
    required this.picLarge,
    required this.picNormal,
    required this.ratingValue,
    required this.ratingCount,
    required this.starCount,
    required this.cardSubtitle,
    required this.type,
  });

  factory DoubanSubject.fromJson(Map<String, dynamic> json) {
    final pic = json['pic'] as Map<String, dynamic>? ?? {};
    final rating = json['rating'] as Map<String, dynamic>? ?? {};
    return DoubanSubject(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      picLarge: pic['large'] as String? ?? '',
      picNormal: pic['normal'] as String? ?? '',
      ratingValue: (rating['value'] as num?)?.toDouble() ?? 0,
      ratingCount: (rating['count'] as num?)?.toInt() ?? 0,
      starCount: (rating['star_count'] as num?)?.toDouble() ?? 0,
      cardSubtitle: json['card_subtitle'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );
  }

  /// 从 card_subtitle 提取年份，如 "2026 / 英国 法国..." → "2026"
  String get year {
    final parts = cardSubtitle.split('/');
    if (parts.isNotEmpty) {
      return parts.first.trim();
    }
    return '';
  }
}

class DoubanHotResponse {
  final int total;
  final List<DoubanSubject> items;

  DoubanHotResponse({
    required this.total,
    required this.items,
  });

  factory DoubanHotResponse.fromJson(Map<String, dynamic> json) => DoubanHotResponse(
        total: (json['total'] as num?)?.toInt() ?? 0,
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => DoubanSubject.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
