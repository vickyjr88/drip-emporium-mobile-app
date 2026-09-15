String? _str(dynamic value) => value?.toString();
String _strOr(dynamic value, String fallback) => _str(value) ?? fallback;

num _num(dynamic value, [num fallback = 0]) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? fallback;
  return fallback;
}

int _int(dynamic value, [int fallback = 1]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// One line in the cart -- a specific variant, not a product, so two sizes of
/// the same shoe are two separate lines. Mirrors web's lib/cart.tsx CartLine
/// exactly, field for field, so the two clients agree on what a cart line is.
class CartLine {
  CartLine({
    required this.variantId,
    required this.productSlug,
    required this.name,
    required this.size,
    required this.sku,
    required this.priceKes,
    required this.imageUrl,
    required this.quantity,
  });

  final String variantId;
  final String productSlug;
  final String name;
  final String size;
  final String sku;
  final num priceKes;
  final String? imageUrl;
  int quantity;

  num get lineTotal => priceKes * quantity;

  factory CartLine.fromJson(Map<String, dynamic> json) {
    return CartLine(
      variantId: _strOr(json['variantId'], ''),
      productSlug: _strOr(json['productSlug'], ''),
      name: _strOr(json['name'], ''),
      size: _strOr(json['size'], ''),
      sku: _strOr(json['sku'], ''),
      priceKes: _num(json['priceKes']),
      imageUrl: _str(json['imageUrl']),
      quantity: _int(json['quantity']),
    );
  }

  Map<String, dynamic> toJson() => {
        'variantId': variantId,
        'productSlug': productSlug,
        'name': name,
        'size': size,
        'sku': sku,
        'priceKes': priceKes,
        'imageUrl': imageUrl,
        'quantity': quantity,
      };
}
