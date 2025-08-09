import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:drip_emporium/providers/cart_provider.dart';

class PaymentService {
  static const String _paystackSecretKey = 'sk_live_0e18be4593c3f83f65b02b5b5d3b1bdfb8f5cb71';

  static Future<void> handlePaymentCallback(
    BuildContext context, 
    String reference, 
    String status
  ) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    
    if (status == 'success') {
      // Verify the payment with Paystack
      final verified = await verifyPayment(reference);
      
      if (verified) {
        // Payment verified successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment Verified Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        cart.clearCart(); // Clear cart on successful payment
        
        // Navigate back to home screen (optional)
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment verification failed. Please contact support.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment was cancelled or failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<bool> verifyPayment(String reference) async {
    try {
      final String verifyUrl = 'https://api.paystack.co/transaction/verify/$reference';
      
      final response = await http.get(
        Uri.parse(verifyUrl),
        headers: {
          'Authorization': 'Bearer $_paystackSecretKey',
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
