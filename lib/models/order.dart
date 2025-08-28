import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';

enum OrderStatus { pending, completed, returned, cancelled }

class Order {
  final String id;
  final String customerId;
  final CustomerType customerTypeAtOrder;
  final List<Map<String, dynamic>> products;
  final double totalAmount;
  final double discountApplied;
  final double bargainPrice;
  final double finalPrice;
  final OrderStatus status;
  final DateTime orderDate;
  final String? storeId;

  Order({
    required this.id,
    required this.customerId,
    required this.customerTypeAtOrder,
    required this.products,
    required this.totalAmount,
    this.discountApplied = 0.0,
    this.bargainPrice = 0.0,
    required this.finalPrice,
    this.status = OrderStatus.pending,
    required this.orderDate,
    this.storeId,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    return Order.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  factory Order.fromMap(Map<String, dynamic> data, String id) {
    return Order(
      id: id,
      customerId: data['customerId'] ?? '',
      customerTypeAtOrder: CustomerType.values.firstWhere(
        (e) =>
            e.toString() ==
            'CustomerType.' + (data['customerTypeAtOrder'] ?? 'client'),
        orElse: () => CustomerType.client,
      ),
      products: List<Map<String, dynamic>>.from(data['products'] ?? []),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      discountApplied: (data['discountApplied'] ?? 0.0).toDouble(),
      bargainPrice: (data['bargainPrice'] ?? 0.0).toDouble(),
      finalPrice: (data['finalPrice'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.' + (data['status'] ?? 'pending'),
        orElse: () => OrderStatus.pending,
      ),
      orderDate:
          (data['orderDate'] is Timestamp)
              ? (data['orderDate'] as Timestamp).toDate()
              : DateTime.parse(data['orderDate'] as String),
      storeId: data['storeId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerTypeAtOrder': customerTypeAtOrder.toString().split('.').last,
      'products': products,
      'totalAmount': totalAmount,
      'discountApplied': discountApplied,
      'bargainPrice': bargainPrice,
      'finalPrice': finalPrice,
      'status': status.toString().split('.').last,
      'orderDate': Timestamp.fromDate(orderDate),
      'storeId': storeId,
    };
  }
}
