import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drip_emporium/providers/cart_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:drip_emporium/screens/user_details_screen.dart';

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
              Text('Initializing payment...'),
            ],
          ),
        );
      },
    );

    try {
      // Initialize Paystack transaction via API
      final String paystackUrl = 'https://api.paystack.co/transaction/initialize';
      final String reference = 'drip_emporium_${DateTime.now().millisecondsSinceEpoch}';
      
      final response = await http.post(
        Uri.parse(paystackUrl),
        headers: {
          'Authorization': 'Bearer sk_live_0b6f6fab28f693068cf13640ee3f4134303fa568', // Your LIVE Secret Key
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'amount': (cart.totalAmount * 100).toInt(), // Amount in kobo
          'email': email,
          'reference': reference,
          'currency': 'KES',
          'callback_url': 'dripemporium://payment-callback', // Deep link callback URL
        }),
      );

      Navigator.of(context).pop(); // Close loading dialog

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == true) {
          final String authorizationUrl = data['data']['authorization_url'];
          
          // Launch the Paystack payment URL in browser
          final Uri paymentUri = Uri.parse(authorizationUrl);
          
          if (await canLaunchUrl(paymentUri)) {
            await launchUrl(
              paymentUri,
              mode: LaunchMode.externalApplication, // Opens in browser
            );
            
            // Show success message - deep link will handle the callback
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment page opened in browser. The app will automatically update when payment is complete.'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 5),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open payment page'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment initialization failed: ${data['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server error: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during payment initialization: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
