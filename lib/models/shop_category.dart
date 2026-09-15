String _strOr(dynamic value, String fallback) => value == null ? fallback : value.toString();
int _int(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

bool _bool(dynamic value, [bool fallback = false]) => value is bool ? value : fallback;

class ShopCategory {
  const ShopCategory({required this.name, required this.slug, required this.productCount, required this.isTopLevel});

  final String name;
  final String slug;
  final int productCount;
  final bool isTopLevel;

  factory ShopCategory.fromJson(Map<String, dynamic> json) {
    return ShopCategory(
      name: _strOr(json['name'], ''),
      slug: _strOr(json['slug'], ''),
      productCount: _int(json['productCount']),
      isTopLevel: _bool(json['isTopLevel'], true),
    );
  }
}
