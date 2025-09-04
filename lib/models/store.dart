import 'package:cloud_firestore/cloud_firestore.dart';

class Store {
  final String id;
  final String name;
  final String address;
  final String mobileNumber;
  final String email;

  Store({
    required this.id,
    required this.name,
    required this.address,
    required this.mobileNumber,
    required this.email,
  });

  factory Store.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Store(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      mobileNumber: data['mobileNumber'] ?? '',
      email: data['email'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'mobileNumber': mobileNumber,
      'email': email,
    };
  }
}
