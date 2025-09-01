import 'package:cloud_firestore/cloud_firestore.dart';

enum CustomerType { client, reseller, shop }

class Customer {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String address;
  final CustomerType customerType;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.customerType,
  });

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Customer(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      customerType: CustomerType.values.firstWhere(
        (e) =>
            e.toString() ==
            'CustomerType.' + (data['customerType'] ?? 'client'),
        orElse: () => CustomerType.client,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'customerType': customerType.toString().split('.').last,
    };
  }
}
