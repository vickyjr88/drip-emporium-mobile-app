String? _str(dynamic value) => value?.toString();
String _strOr(dynamic value, String fallback) => _str(value) ?? fallback;

num? _numOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

/// The light shape GET /customer-portal/favorites returns -- enough for a
/// grid card and a link through to the real product page, not the full
/// Product (no variants, no description).
class FavoriteProduct {
  const FavoriteProduct({
    required this.productId,
    required this.slug,
    required this.name,
    required this.imageUrl,
    required this.priceFrom,
  });

  final String productId;
  final String slug;
  final String name;
  final String? imageUrl;
  final num? priceFrom;

  factory FavoriteProduct.fromJson(Map<String, dynamic> json) {
    return FavoriteProduct(
      productId: _strOr(json['productId'], ''),
      slug: _strOr(json['slug'], ''),
      name: _strOr(json['name'], ''),
      imageUrl: _str(json['imageUrl']),
      priceFrom: _numOrNull(json['priceFrom']),
    );
  }
}
