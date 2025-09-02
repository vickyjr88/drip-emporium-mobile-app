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

enum PaymentMethod { payLater, payToTill, mpesa, card }

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
  PaymentMethod? _selectedPaymentMethod = PaymentMethod.mpesa;

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
    String customerId,
  ) async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    CustomerType? customerTypeAtOrder = cart.customerType;
    if (_customerType == CustomerType.reseller) {
      final selectedCustomerType = await _showCustomerSelectionDialog();
      if (selectedCustomerType == null) {
        return; // User cancelled the dialog
      }
      customerTypeAtOrder = selectedCustomerType;
    }

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
              Text('Processing order...'),
            ],
          ),
        );
      },
    );

    try {
      final orderId = await _saveOrderToFirestore(
        context,
        cart,
        email,
        name,
        mobileNumber,
        address,
        _selectedPaymentMethod!,
        customerTypeAtOrder,
        customerId,
      );

      if (_selectedPaymentMethod == PaymentMethod.mpesa ||
          _selectedPaymentMethod == PaymentMethod.card) {
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
      } else {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        cart.clearCart();
        Navigator.of(context).pop();
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
    PaymentMethod paymentMethod,
    CustomerType customerType,
    String customerId,
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
        'userId': customerId,
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
        'customerTypeAtOrder': customerType.toString().split('.').last,
        'discountApplied': cart.discountPercentage,
        'bargainPrice': cart.bargainAmount,
        'finalPrice': cart.finalPrice,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'initiated', // Initial status
        'paymentMethod': paymentMethod.toString().split('.').last,
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

  Future<CustomerType?> _showCustomerSelectionDialog() async {
    return await showDialog<CustomerType>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Customer Type'),
          content: DropdownButton<CustomerType>(
            value: CustomerType.client,
            onChanged: (CustomerType? newValue) {
              if (newValue != null) {
                Navigator.of(context).pop(newValue);
              }
            },
            items: CustomerType.values
                .map<DropdownMenuItem<CustomerType>>((CustomerType type) {
              return DropdownMenuItem<CustomerType>(
                value: type,
                child: Text(
                  type.toString().split('.').last.toUpperCase(),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
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
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
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
                                        if (item['quantity'] == 1) {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text('Remove Item?'),
                                                content: const Text(
                                                    'Are you sure you want to remove this item from your cart?'),
                                                actions: [
                                                  TextButton(
                                                    child: const Text('Cancel'),
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                    },
                                                  ),
                                                  TextButton(
                                                    child: const Text('Remove'),
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                      cart.decreaseItemQuantity(productId);
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        } else {
                                          cart.decreaseItemQuantity(productId);
                                        }
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
                                    if (cart.items.length == 1) {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Remove Last Item?'),
                                            content: const Text(
                                                'Are you sure you want to remove the last item from your cart?'),
                                            actions: [
                                              TextButton(
                                                child: const Text('Cancel'),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                              TextButton(
                                                child: const Text('Remove'),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  cart.removeItem(productId);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          '${item['name']} removed from cart!'),
                                                      duration: const Duration(seconds: 1),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    } else {
                                      cart.removeItem(productId);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${item['name']} removed from cart!'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ), // This closes the ListTile
                            ),
                          );
                        },
                      ),
                      if (showShopFeatures)
                        // Customer Type Selection
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: Wrap(
                            spacing: 8.0,
                            children: CustomerType.values.map((type) {
                              return ChoiceChip(
                                label: Text(type.toString().split('.').last.toUpperCase()),
                                selected: cart.customerType == type,
                                onSelected: (selected) {
                                  if (selected) {
                                    cart.setCustomerType(type);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          PaymentMethodCard(
                            method: PaymentMethod.payLater,
                            icon: Icons.history,
                            label: 'Pay Later',
                            isSelected: _selectedPaymentMethod == PaymentMethod.payLater,
                            onTap: () {
                              setState(() {
                                _selectedPaymentMethod = PaymentMethod.payLater;
                              });
                            },
                          ),
                          PaymentMethodCard(
                            method: PaymentMethod.payToTill,
                            icon: Icons.store,
                            label: 'Pay to Till',
                            isSelected: _selectedPaymentMethod == PaymentMethod.payToTill,
                            onTap: () {
                              setState(() {
                                _selectedPaymentMethod = PaymentMethod.payToTill;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          PaymentMethodCard(
                            method: PaymentMethod.mpesa,
                            icon: Icons.phone_android,
                            label: 'Mpesa',
                            isSelected: _selectedPaymentMethod == PaymentMethod.mpesa,
                            onTap: () {
                              setState(() {
                                _selectedPaymentMethod = PaymentMethod.mpesa;
                              });
                            },
                          ),
                          PaymentMethodCard(
                            method: PaymentMethod.card,
                            icon: Icons.credit_card,
                            label: 'Card',
                            isSelected: _selectedPaymentMethod == PaymentMethod.card,
                            onTap: () {
                              setState(() {
                                _selectedPaymentMethod = PaymentMethod.card;
                              });
                            },
                          ),
                        ],
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
                                          customerId,
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
                                            customerId,
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
                ), 
    );
  }
}

class PaymentMethodCard extends StatelessWidget {
  final PaymentMethod method;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const PaymentMethodCard({
    super.key,
    required this.method,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: isSelected ? Theme.of(context).primaryColor : Colors.white,
        child: SizedBox(
          width: 150,
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: isSelected ? Colors.white : Colors.black,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}