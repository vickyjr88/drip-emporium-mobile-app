import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:drip_emporium/providers/cart_provider.dart';
import 'package:paystack_flutter_sdk/paystack_flutter_sdk.dart'; // New import
import 'package:flutter/services.dart'; // For PlatformException
import 'package:drip_emporium/config/app_config.dart'; // New import
import 'package:cloud_firestore/cloud_firestore.dart'; // New import

class PaymentService {
  final Paystack _paystack = Paystack(); // Initialize Paystack instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Initialize Firestore

  // Method to update order status in Firestore
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({'status': status});
      print('Order $orderId status updated to $status');
    } catch (e) {
      print('Error updating order status for $orderId to $status: $e');
      // Optionally, you could show a toast here, but it might be better to handle in UI
    }
  }

  // Method to initialize the SDK
  Future<bool> initializePaystack(String publicKey) async {
    try {
      final response = await _paystack.initialize(publicKey, true); // allow logging
      if (response) {
        print("Successfully initialised the SDK");
        return true;
      } else {
        print("Unable to initialise the SDK");
        return false;
      }
    } on PlatformException catch (e) {
      print('Error initializing Paystack SDK: ${e.message}');
      return false;
    }
  }

  // Method to launch the payment UI
  Future<void> launchPayment(BuildContext context, String accessCode) async {
    try {
      final response = await _paystack.launch(accessCode);
      if (response.status == "success") {
        final reference = response.reference;
        print("Payment successful, reference: $reference");
        // Now verify the payment on your server
        final verified = await verifyPayment(reference!); // reference is non-null on success

        if (verified) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment Verified Successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          final cart = Provider.of<CartProvider>(context, listen: false);
          cart.clearCart();
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment verification failed. Please contact support.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else if (response.status == "cancelled") {
        print("Payment cancelled: ${response.message}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment was cancelled'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        print("Payment failed: ${response.message}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on PlatformException catch (e) {
      print('Error launching payment: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error launching payment: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // This method remains largely the same for server-side verification
  static Future<bool> verifyPayment(String reference) async {
    try {
      final String verifyUrl = 'https://api.paystack.co/transaction/verify/$reference';

      // IMPORTANT: The secret key should NOT be exposed on the client-side.
      // This verification should ideally happen on your backend server.
      // For demonstration, I'm using a placeholder.
      final response = await http.get(
        Uri.parse(verifyUrl),
        headers: {
          'Authorization': 'Bearer ${AppConfig.paystackSecretKey}', // Use from AppConfig
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['status'] == true && data['data']['status'] == 'success';
      }

      return false;
    } catch (e) {
      print('Error verifying payment: $e');
      return false;
    }
  }
}
