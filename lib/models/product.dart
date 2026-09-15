/// Tolerant JSON coercion helpers, shared by every model in this file.
///
/// A raw cast (`json['x'] as String`) throws the instant one field is a
/// different type or missing -- which would take down an entire grid of 80+
/// products over a single bad row. Every field here is coerced-and-defaulted
/// instead, so a malformed product renders with gaps rather than crashing
/// the screen it's in.
String? _str(dynamic value) => value?.toString();

String _strOr(dynamic value, String fallback) => _str(value) ?? fallback;

num _num(dynamic value, [num fallback = 0]) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? fallback;
  return fallback;
}

num? _numOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

bool _bool(dynamic value, [bool fallback = false]) => value is bool ? value : fallback;

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<String>().where((item) => item.isNotEmpty).toList();
}

class ProductCategory {
  const ProductCategory({required this.name, required this.slug});

  final String name;
  final String slug;

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(name: _strOr(json['name'], ''), slug: _strOr(json['slug'], ''));
  }
}

class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.sku,
    required this.name,
    required this.size,
    required this.priceKes,
    required this.wasPriceKes,
    required this.offerLabel,
    required this.retailPriceKes,
    required this.inStock,
    required this.canOrder,
  });

  final String id;
  final String sku;
  final String name;
  /// The category's size-like attribute value (e.g. "EUR 42"). Null for a
  /// sizeless category (Watches, Perfumes) -- callers must never assume this
  /// is present; use [displayLabel] instead of reading it directly.
  final String? size;
  final num priceKes;
  final num? wasPriceKes;
  final String? offerLabel;
  /// Present only for a logged-in reseller/wholesale customer: retail, for
  /// comparison against the tier price in [priceKes].
  final num? retailPriceKes;
  final bool inStock;
  final bool canOrder;

  /// What to show on a size chip -- falls back to the variant's own name for
  /// a sizeless product, so the UI never has to special-case a null size.
  String get displayLabel => size ?? name;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: _strOr(json['id'], ''),
      sku: _strOr(json['sku'], ''),
      name: _strOr(json['name'], ''),
      size: _str(json['size']),
      priceKes: _num(json['priceKes']),
      wasPriceKes: _numOrNull(json['wasPriceKes']),
      offerLabel: _str(json['offerLabel']),
      retailPriceKes: _numOrNull(json['retailPriceKes']),
      inStock: _bool(json['inStock']),
      canOrder: _bool(json['canOrder'], true),
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.slug,
    required this.name,
    required this.brand,
    required this.description,
    required this.imageUrls,
    required this.category,
    required this.isFeatured,
    required this.variants,
    required this.priceFrom,
    required this.priceTo,
    required this.retailPriceFrom,
    required this.sizesInStock,
    required this.anyInStock,
    required this.onOffer,
    required this.offerLabel,
  });

  final String id;
  final String slug;
  final String name;
  final String? brand;
  final String? description;
  final List<String> imageUrls;
  final ProductCategory? category;
  final bool isFeatured;
  final List<ProductVariant> variants;
  final num priceFrom;
  final num priceTo;
  final num? retailPriceFrom;
  final List<String> sizesInStock;
  final bool anyInStock;
  final bool onOffer;
  final String? offerLabel;

  String? get primaryImageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  /// Whether a size selector should render at all. A sizeless category
  /// (Watches, Perfumes) has exactly one variant whose `size` is null --
  /// exact rule from the web storefront's shop/[slug]/product-client.tsx.
  bool get hasSizes => variants.length > 1 || (variants.isNotEmpty && variants.first.size != null);

  /// "KSh 3,500" or "from KSh 3,500" when sizes are priced differently --
  /// mirrors web's lib/shop.ts priceLabel().
  String priceLabel(String Function(num) formatKes) {
    return priceFrom == priceTo ? formatKes(priceFrom) : 'from ${formatKes(priceFrom)}';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final variantsJson = json['variants'];
    final variants = variantsJson is List
        ? variantsJson.whereType<Map<String, dynamic>>().map(ProductVariant.fromJson).toList()
        : <ProductVariant>[];

    final categoryJson = json['category'];

    return Product(
      id: _strOr(json['id'], ''),
      slug: _strOr(json['slug'], ''),
      name: _strOr(json['name'], ''),
      brand: _str(json['brand']),
      description: _str(json['description']),
      imageUrls: _stringList(json['imageUrls']),
      category: categoryJson is Map<String, dynamic> ? ProductCategory.fromJson(categoryJson) : null,
      isFeatured: _bool(json['isFeatured']),
      variants: variants,
      priceFrom: _num(json['priceFrom']),
      priceTo: _num(json['priceTo']),
      retailPriceFrom: _numOrNull(json['retailPriceFrom']),
      sizesInStock: _stringList(json['sizesInStock']),
      anyInStock: _bool(json['anyInStock']),
      onOffer: _bool(json['onOffer']),
      offerLabel: _str(json['offerLabel']),
    );
  }
}
