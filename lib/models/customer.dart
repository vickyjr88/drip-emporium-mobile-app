import 'package:cloud_firestore/cloud_firestore.dart' as bringModule;

enum CustomerType { client, reseller, shop }

class Customer {
  final String id;
  final String displayName;
  final String email;
  final String mobileNumber;
  final String address;
  final CustomerType customerType;

  Customer({
    required this.id,
    required this.displayName,
    required this.email,
    required this.mobileNumber,
    required this.address,
    required this.customerType,
  });

  factory Customer.fromFirestore(bringModule.DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Customer(
      id: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      mobileNumber: data['mobileNumber'] ?? '',
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
      'name': displayName,
      'email': email,
      'mobileNumber': mobileNumber,
      'address': address,
      'customerType': customerType.toString().split('.').last,
    };
  }
}
