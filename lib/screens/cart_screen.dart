import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drip_emporium/providers/cart_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON encoding/decoding
import '../models/customer.dart';
import 'dart:io'; // New import
// import 'package:url_launcher/url_launcher.dart'; // Removed
import 'package:drip_emporium/screens/user_details_screen.dart';
import 'package:drip_emporium/services/payment_service.dart'; // New import
import 'package:drip_emporium/config/app_config.dart'; // New import
import 'package:cloud_firestore/cloud_firestore.dart'; // New import
import 'package:firebase_auth/firebase_auth.dart'; // New import
import '../models/attender.dart';

class CartScreen extends StatefulWidget {
  final PaymentService paymentService; // New field
  const CartScreen({
    super.key,
    required this.paymentService,
  }); // Updated constructor

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  CustomerType? _customerType;
  bool _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check for super admin status
    try {
      final doc = await FirebaseFirestore.instance
          .collection('superAdmins')
          .doc(user.uid)
          .get();
      setState(() {
        _isSuperAdmin = doc.exists;
      });
    } catch (e) {
      print('Error checking super admin status: $e');
    }

    // Fetch customer type
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _customerType = CustomerType.values.firstWhere(
            (e) =>
                e.toString() ==
                'CustomerType.' + (data['customerType'] ?? 'client'),
            orElse: () => CustomerType.client,
          );
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _handleCheckout(
    BuildContext context,
    CartProvider cart,
    String email,
    String name,
    String mobileNumber,
    String address,
  ) async {
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
      // Save order to Firestore before initiating payment
      final orderId = await _saveOrderToFirestore(
        context,
        cart,
        email,
        name,
        mobileNumber,
        address,
      );

      // Initialize Paystack transaction via API
      final String paystackUrl =
          'https://api.paystack.co/transaction/initialize';
      final String reference = orderId!; // Use orderId as reference

      final response = await http.post(
        Uri.parse(paystackUrl),
        headers: {
          'Authorization':
              'Bearer ${AppConfig.paystackLiveSecretKey}', // Use from AppConfig
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'amount': (cart.totalAmount * 100).toInt(), // Amount in kobo
          'email': email,
          'reference': reference,
          'currency': 'KES',
          'callback_url':
              'dripemporium://payment-callback', // Deep link callback URL
          'channels': [
            'card',
            'bank',
            'ussd',
            'qr',
            'mobile_money',
            'bank_transfer',
            'eft',
          ], // All available channels
        }),
      );

      Navigator.of(context).pop(); // Close loading dialog

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == true) {
          final String accessCode =
              data['data']['access_code']; // Get access_code

          // Launch the Paystack payment UI using the SDK
          await widget.paymentService.launchPayment(
            context,
            accessCode,
          ); // Call SDK method
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment initialization failed: ${data['message']}',
              ),
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
    } on SocketException catch (_) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No internet connection. Please check your network settings.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'An unexpected error occurred: ${e.toString()}. Please try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _saveOrderToFirestore(
    BuildContext context,
    CartProvider cart,
    String email,
    String name,
    String mobileNumber,
    String address,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not logged in. Cannot save order.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need to be logged in to place an order.'),
            backgroundColor: Colors.orange,
          ),
        );
        return null;
      }

      final Map<String, dynamic> orderData = {
        'userId': user.uid,
        'email': email,
        'name': name,
        'mobileNumber': mobileNumber,
        'address': address,
        'items':
            cart.items.entries.map((entry) {
              return {
                'productId': entry.key,
                'name': entry.value['name'],
                'price': entry.value['price'],
                'quantity': entry.value['quantity'],
                'imageUrl': entry.value['imageUrl'],
              };
            }).toList(),
        'totalAmount': cart.totalAmount,
        'customerTypeAtOrder': cart.customerType.toString().split('.').last,
        'discountApplied': cart.discountPercentage,
        'bargainPrice': cart.bargainAmount,
        'finalPrice': cart.finalPrice,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'initiated', // Initial status
      };

      String? attenderId;
      String? storeId;

      if (_isSuperAdmin) {
        try {
          final attenderDoc = await FirebaseFirestore.instance
              .collection('attenders')
              .doc(user.uid)
              .get();
          if (attenderDoc.exists) {
            final attender = Attender.fromFirestore(attenderDoc);
            attenderId = attender.id;
            storeId = attender.storeId;
          }
        } catch (e) {
          print('Error fetching attender data for admin: $e');
        }
      }

      // If no attender is found, use the default attender
      if (attenderId == null) {
        try {
          final attenderQuery = await FirebaseFirestore.instance
              .collection('attenders')
              .where('email', isEqualTo: 'vickyjr88@gmail.com')
              .limit(1)
              .get();

          if (attenderQuery.docs.isNotEmpty) {
            final attender = Attender.fromFirestore(attenderQuery.docs.first);
            attenderId = attender.id;
            storeId = attender.storeId;
          } else {
            print('Default attender not found.');
            // Handle the case where the default attender is not found
          }
        } catch (e) {
          print('Error fetching default attender: $e');
        }
      }

      if (attenderId != null) {
        orderData['attenderId'] = attenderId;
        orderData['storeId'] = storeId;
      }

      final docRef = await FirebaseFirestore.instance
          .collection('orders')
          .add(orderData);
      print('Order saved to Firestore with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error saving order to Firestore: $e');
      throw e; // Re-throw the exception
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final bool showShopFeatures =
        _customerType == CustomerType.reseller ||
        _customerType == CustomerType.shop ||
        _isSuperAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body:
          cart.items.isEmpty
              ? const Center(child: Text('Your cart is empty.'))
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cart.items.length,
                      itemBuilder: (context, index) {
                        final productId = cart.items.keys.elementAt(index);
                        final item = cart.items[productId]!;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 4,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ListTile(
                              leading: SizedBox(
                                width: 60.0, // Example width for the square
                                height: 60.0, // Example height for the square
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    8.0,
                                  ), // Optional: for rounded corners
                                  child: Image(
                                    image: NetworkImage(item['imageUrl']),
                                    fit:
                                        BoxFit
                                            .cover, // Ensures image covers the square, cropping if necessary
                                  ),
                                ),
                              ),
                              title: Text(item['name']),
                              subtitle: Row(
                                // New Row for quantity controls
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      cart.decreaseItemQuantity(productId);
                                    },
                                  ),
                                  Text('${item['quantity']}'),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      cart.increaseItemQuantity(productId);
                                    },
                                  ),
                                  const Spacer(), // Pushes price to the right
                                  Text(
                                    'KES ${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                  ), // Display total price for item
                                ],
                              ),
                              trailing: IconButton(
                                // Delete button remains
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  cart.removeItem(productId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${item['name']} removed from cart!',
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            ), // This closes the ListTile
                          ),
                        );
                      },
                    ),
                  ),
                  if (showShopFeatures)
                    // Customer Type Selection
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        children: [
                          const Text('Customer Type:'),
                          const SizedBox(width: 10),
                          DropdownButton<CustomerType>(
                            value: cart.customerType,
                            onChanged: (CustomerType? newValue) {
                              if (newValue != null) {
                                cart.setCustomerType(newValue);
                              }
                            },
                            items:
                                CustomerType.values
                                    .map<DropdownMenuItem<CustomerType>>((
                                      CustomerType type,
                                    ) {
                                      return DropdownMenuItem<CustomerType>(
                                        value: type,
                                        child: Text(
                                          type
                                              .toString()
                                              .split('.')
                                              .last
                                              .toUpperCase(),
                                        ),
                                      );
                                    })
                                    .toList(),
                          ),
                        ],
                      ),
                    ),
                  if (showShopFeatures)
                    // Discount Input
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        children: [
                          const Text('Discount (%):'),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final discount = double.tryParse(value) ?? 0.0;
                                cart.applyDiscount(discount);
                              },
                              decoration: const InputDecoration(
                                hintText: 'Enter discount percentage',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (showShopFeatures)
                    // Bargain Amount Input
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        children: [
                          const Text('Bargain Amount:'),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final bargain = double.tryParse(value) ?? 0.0;
                                cart.setBargainAmount(bargain);
                              },
                              decoration: const InputDecoration(
                                hintText: 'Enter bargain amount',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  Card(
                    margin: const EdgeInsets.all(15),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'KES ${cart.finalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context)
                                      .colorScheme
                                      .primary, // Changed to primary (blue)
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
                              builder:
                                  (ctx) => UserDetailsScreen(
                                    onProceedToPayment: (
                                      email,
                                      name,
                                      mobileNumber,
                                      address,
                                    ) {
                                      Navigator.of(
                                        ctx,
                                      ).pop(); // Pop UserDetailsScreen
                                      _handleCheckout(
                                        context,
                                        cart,
                                        email,
                                        name,
                                        mobileNumber,
                                        address,
                                      );
                                    },
                                  ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context)
                                  .colorScheme
                                  .primary, // Changed to primary (blue)
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