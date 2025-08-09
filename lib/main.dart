import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drip_emporium/services/data_repository.dart';
import 'package:drip_emporium/providers/products_provider.dart';
import 'package:drip_emporium/providers/cart_provider.dart';
import 'package:drip_emporium/screens/product_details_screen.dart';
import 'package:drip_emporium/screens/cart_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:drip_emporium/services/payment_service.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dataRepository = DataRepository();
  await dataRepository.initDatabase();
  runApp(
    MultiProvider( // Use MultiProvider for multiple providers
      providers: [
        ChangeNotifierProvider(create: (context) => ProductsProvider(dataRepository)),
        ChangeNotifierProvider(create: (context) => CartProvider()), // New provider
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget { // Changed to StatefulWidget
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initAppLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initAppLinks() async {
    _appLinks = AppLinks();

    // Get initial link if app was launched via a deep link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink.toString());
      }
    } on PlatformException {
      // Handle exception
      print('Failed to get initial link.');
    }

    // Listen for incoming links while the app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
      _handleDeepLink(uri.toString());
    }, onError: (err) {
      // Handle error
      print('Error receiving deep link: $err');
    });
  }

  void _handleDeepLink(String link) {
    // Parse the link and navigate accordingly
    final uri = Uri.parse(link);
    if (uri.path == '/payment-success' || uri.path == '/payment-callback') {
      // Handle payment callback
      final reference = uri.queryParameters['reference'] ?? '';
      final status = uri.queryParameters['status'] ?? '';
      
      print('Payment callback received: reference=$reference, status=$status');
      
      if (reference.isNotEmpty) {
        // Use the payment service to handle the callback
        PaymentService.handlePaymentCallback(context, reference, status);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drip Emporium',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Primary color for the app
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(
          primary: Colors.blue, // Explicitly set primary color
          secondary: Colors.red, // Secondary color for accents/CTAs
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drip Emporium'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartScreen()),
                      );
                    },
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          cart.itemCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<ProductsProvider>(
        builder: (context, productsProvider, child) {
          if (productsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (productsProvider.errorMessage != null) {
            return Center(child: Text('Error: ${productsProvider.errorMessage}'));
          } else if (productsProvider.products.isEmpty) {
            return const Center(child: Text('No products found.'));
          } else {
            return GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.7, // Adjust as needed
              ),
              itemCount: productsProvider.products.length,
              itemBuilder: (context, index) {
                final product = productsProvider.products[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsScreen(product: product),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CachedNetworkImage(
                            imageUrl: product['imageUrl'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            product['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'KES ${product['price'].toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary, // Changed to primary (blue)
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: IconButton(
                            icon: Icon(Icons.add_shopping_cart, color: Theme.of(context).colorScheme.primary), // Changed to primary (blue)
                            onPressed: () {
                              Provider.of<CartProvider>(context, listen: false).addItem(
                                product['id'],
                                product['name'],
                                product['price'],
                                product['imageUrl'],
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${product['name']} added to cart!'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
