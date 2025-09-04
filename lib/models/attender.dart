import 'package:cloud_firestore/cloud_firestore.dart';

class Attender {
  final String id;
  final String name;
  final String email;
  final String storeId;
  final String role;
  final String mobileNumber;

  Attender({
    required this.id,
    required this.name,
    required this.email,
    required this.storeId,
    required this.role,
    required this.mobileNumber,
  });

  factory Attender.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Attender(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      storeId: data['storeId'] ?? '',
      role: data['role'] ?? '',
      mobileNumber: data['mobileNumber'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'storeId': storeId,
      'role': role,
      'mobileNumber': mobileNumber,
    };
  }
}
