import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drip_emporium/providers/cart_provider.dart';
// TODO: Add Paystack integration later
// import 'package:paystack_flutter_sdk/paystack_flutter_sdk.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _handleCheckout(BuildContext context, CartProvider cart) async {
    // TODO: Implement Paystack integration
    // For now, just show a success message and clear cart
    
    // Simulate a payment processing delay
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
    
    // Simulate processing time
    await Future.delayed(const Duration(seconds: 2));
    
    Navigator.of(context).pop(); // Close the loading dialog
    
    // Simulate successful payment
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment Successful! (Demo Mode)'),
        backgroundColor: Colors.green,
      ),
    );
    
    cart.clearCart(); // Clear cart on successful payment
    Navigator.of(context).pop(); // Go back to previous screen
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
                      onPressed: () => _handleCheckout(context, cart), // Call the checkout method
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
