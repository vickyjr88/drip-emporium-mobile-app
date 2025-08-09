import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drip_emporium/providers/cart_provider.dart';
import 'package:paystack_flutter_sdk/paystack_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:drip_emporium/screens/user_details_screen.dart'; // New import

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _handleCheckout(BuildContext context, CartProvider cart, String email, String name) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Processing payment...'),
            ],
          ),
        );
      },
    );

    try {
      // TODO: Implement Paystack integration once the SDK API is stable
      // For now, simulate a successful payment after a delay
      await Future.delayed(const Duration(seconds: 2));
      
      Navigator.of(context).pop(); // Close loading dialog
      
      // Simulate successful payment
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment Successful! (Demo Mode)'),
          backgroundColor: Colors.green,
        ),
      );
      
      cart.clearCart(); // Clear cart on successful payment
      Navigator.of(context).pop(); // Go back to previous screen
      
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during checkout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    // TODO: Uncomment and fix when Paystack SDK API is stable
    /*
    // Replace with your actual LIVE Paystack Public Key
    PaystackSdk.initialize(publicKey: 'pk_live_26734e4f7302191b56b0ad0f9314bc75563e641c');

    final String backendUrl = 'http://shengmtaa.com/api/private/donate-mobile';

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'amount': (cart.totalAmount * 100).toInt(),
          'email': email,
          'reference': DateTime.now().millisecondsSinceEpoch.toString(),
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String accessCode = data['data']['access_code'];

        // Use correct Paystack SDK API when available
        final checkoutResponse = await PaystackSdk.chargeAccessCode(
          context: context,
          accessCode: accessCode,
        );

        if (checkoutResponse.status) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment Successful!')),
          );
          cart.clearCart();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment Failed: ${checkoutResponse.message}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during checkout: $e')),
      );
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: cart.items.isEmpty
          ? const Center(
              child: Text('Your cart is empty.'),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final productId = cart.items.keys.elementAt(index);
                      final item = cart.items[productId]!;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(item['imageUrl']),
                            ),
                            title: Text(item['name']),
                            subtitle: Text('Quantity: ${item['quantity']}'),
                            trailing: Text('KES ${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                            onTap: () {
                              // Optionally, allow editing quantity or viewing product details
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  margin: const EdgeInsets.all(15),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'KES ${cart.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary, // Changed to primary (blue)
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => UserDetailsScreen(
                              onProceedToPayment: (email, name) {
                                Navigator.of(ctx).pop(); // Pop UserDetailsScreen
                                _handleCheckout(context, cart, email, name);
                              },
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary, // Changed to primary (blue)
                        padding: const EdgeInsets.symmetric(vertical: 15.0),
                      ),
                      child: const Text(
                        'Checkout',
                        style: TextStyle(fontSize: 18.0, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
