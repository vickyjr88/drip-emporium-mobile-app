String? _str(dynamic value) => value?.toString();
String _strOr(dynamic value, String fallback) => _str(value) ?? fallback;

num _num(dynamic value, [num fallback = 0]) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? fallback;
  return fallback;
}

int _int(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

class OrderStore {
  const OrderStore({required this.name, required this.location});

  final String name;
  final String? location;

  factory OrderStore.fromJson(Map<String, dynamic> json) {
    return OrderStore(name: _strOr(json['name'], ''), location: _str(json['location']));
  }
}

class OrderLine {
  const OrderLine({
    required this.description,
    required this.quantity,
    required this.lineTotal,
    required this.imageUrl,
    required this.sku,
  });

  final String description;
  final int quantity;
  final num lineTotal;
  /// Present on GET /customer-portal/orders, absent on the guest-safe
  /// GET /checkout/orders/:reference lookup (which returns `sku` instead) --
  /// both are tolerated since this model covers both response shapes.
  final String? imageUrl;
  final String? sku;

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    return OrderLine(
      description: _strOr(json['description'], ''),
      quantity: _int(json['quantity'], 1),
      lineTotal: _num(json['lineTotal']),
      imageUrl: _str(json['imageUrl']),
      sku: _str(json['sku']),
    );
  }
}

/// Plain JSON, unlike the old Firestore-coupled Order model (no Timestamp,
/// no `fromFirestore`). Covers both GET /customer-portal/orders (a signed-in
/// customer's own history) and GET /checkout/orders/:reference (the guest-safe
/// post-payment lookup) -- their shapes differ slightly (id/placedAt/status
/// as an enum vs a plain string, customerName only on the latter), so every
/// field that isn't common to both is nullable.
class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.placedAt,
    required this.total,
    required this.amountPaid,
    required this.customerName,
    required this.shippingAddress,
    required this.store,
    required this.lines,
  });

  final String? id;
  final String orderNumber;
  final String status;
  final DateTime? placedAt;
  final num total;
  final num amountPaid;
  final String? customerName;
  final String? shippingAddress;
  final OrderStore? store;
  final List<OrderLine> lines;

  num get owing => (total - amountPaid).clamp(0, total);

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    final linesJson = json['lines'];
    final lines = linesJson is List
        ? linesJson.whereType<Map<String, dynamic>>().map(OrderLine.fromJson).toList()
        : <OrderLine>[];

    final storeJson = json['store'];
    final placedAtRaw = _str(json['placedAt']);

    return CustomerOrder(
      id: _str(json['id']),
      orderNumber: _strOr(json['orderNumber'], ''),
      status: _strOr(json['status'], ''),
      placedAt: placedAtRaw != null ? DateTime.tryParse(placedAtRaw) : null,
      total: _num(json['total']),
      amountPaid: _num(json['amountPaid']),
      customerName: _str(json['customerName']),
      shippingAddress: _str(json['shippingAddress']),
      store: storeJson is Map<String, dynamic> ? OrderStore.fromJson(storeJson) : null,
      lines: lines,
    );
  }
}
