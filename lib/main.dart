import 'package:drip_emporium/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drip_emporium/services/data_repository.dart';
import 'package:drip_emporium/providers/products_provider.dart';
import 'package:drip_emporium/providers/cart_provider.dart';
import 'package:drip_emporium/providers/favorites_provider.dart'; // New import
import 'package:drip_emporium/screens/product_details_screen.dart';
import 'package:drip_emporium/screens/cart_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:drip_emporium/services/payment_service.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:drip_emporium/config/app_config.dart'; // New import
import 'package:share_plus/share_plus.dart'; // New import
import 'package:firebase_core/firebase_core.dart'; // New import
import 'package:firebase_auth/firebase_auth.dart'; // New import
import 'package:drip_emporium/screens/profile_screen.dart'; // New import
import 'package:url_launcher/url_launcher.dart'; // New import
import 'package:drip_emporium/screens/bottom_nav_bar_screen.dart';
import 'package:drip_emporium/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  
  final dataRepository = DataRepository();
  await dataRepository.initDatabase();
  runApp(
    MultiProvider( // Use MultiProvider for multiple providers
      providers: [
        ChangeNotifierProvider(create: (context) => ProductsProvider(dataRepository)),
        ChangeNotifierProvider(create: (context) => CartProvider()), // New provider
        ChangeNotifierProvider(create: (context) => FavoritesProvider()), // New provider
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
  late PaymentService _paymentService; // Declare PaymentService

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService(); // Initialize PaymentService
    _paymentService.initializePaystack(AppConfig.paystackPublicKey); // Use from AppConfig
    _initAppLinks();
    _checkAndCreateUserDocument(); // Check if user is logged in and create/update document
  }

  Future<void> _checkAndCreateUserDocument() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final dataRepository = DataRepository();
        await dataRepository.createOrUpdateUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoURL: user.photoURL,
          phoneNumber: user.phoneNumber,
        );
        print('User document checked/updated for existing user: ${user.uid}');
      }
    } catch (e) {
      print('Error checking/creating user document on app start: $e');
    }
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

  void _handleDeepLink(String link) async {
    // Parse the link and navigate accordingly
    final uri = Uri.parse(link);
    if (uri.path == '/payment-success' || uri.path == '/payment-callback') {
      // Handle payment callback
      final reference = uri.queryParameters['reference'] ?? '';
      final status = uri.queryParameters['status'] ?? '';
      
      print('Payment callback received: reference=$reference, status=$status');
      
      if (reference.isNotEmpty) {
        // Use the payment service to handle the callback
        if (status == 'success') {
          _paymentService.updateOrderStatus(reference, 'verifying'); // Update order status to verifying
          final verified = await PaymentService.verifyPayment(reference);
          if (verified) {
            _paymentService.updateOrderStatus(reference, 'successful'); // Update order status
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment Verified Successfully via Deep Link!'),
                backgroundColor: Colors.green,
              ),
            );
            final cart = Provider.of<CartProvider>(context, listen: false);
            cart.clearCart();
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            _paymentService.updateOrderStatus(reference, 'failed'); // Update order status
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Deep link payment verification failed. Please contact support.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          _paymentService.updateOrderStatus(reference, 'failed'); // Update order status
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deep link payment was cancelled or failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
      home: BottomNavBarScreen(paymentService: _paymentService),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final PaymentService paymentService; // New field
  const HomeScreen({super.key, required this.paymentService}); // Updated constructor

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    Provider.of<ProductsProvider>(context, listen: false).setSearchQuery(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drip Emporium'),
        actions: [
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              return IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              );
            },
          ),
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CartScreen(paymentService: widget.paymentService)), // Pass paymentService
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight), // Height of the search bar
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              ),
            ),
          ),
        ),
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
                        builder: (context) => ProductDetailsScreen(product: product, paymentService: widget.paymentService), // Pass paymentService
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SizedBox( // New SizedBox to enforce square height
                            height: 150.0, // Example height for the square
                            child: CachedNetworkImage(
                              imageUrl: product['imageUrl'],
                              fit: BoxFit.cover, // Ensures image covers the square, cropping if necessary
                              width: double.infinity,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image)),
                            ),
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'KES ${product['price'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary, // Changed to primary (blue)
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.0,
                                ),
                              ),
                              IconButton( // Share icon
                                padding: EdgeInsets.zero, // Reduce padding
                                icon: Icon(Icons.share, color: Theme.of(context).colorScheme.primary),
                                onPressed: () {
                                  Share.share('Check out this product: ${product['name']} - KES ${product['price'].toStringAsFixed(2)} ${product['link']}');
                                },
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Row( // New Row to contain add-to-cart and share icons
                            mainAxisSize: MainAxisSize.max, // To occupy all available space
                            mainAxisAlignment: MainAxisAlignment.spaceAround, // Spread evenly
                            children: [
                              IconButton( // Add to cart icon
                                padding: EdgeInsets.zero, // Reduce padding
                                icon: Icon(Icons.add_shopping_cart, color: Theme.of(context).colorScheme.primary),
                                onPressed: () {
                                  Provider.of<CartProvider>(context, listen: false).addItem(
                                    product['id'],
                                    product['name'],
                                    product['price'],
                                    product['imageUrl'],
                                    product['link'],
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${product['name']} added to cart!'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                              // New Favorite Icon
                              Consumer<FavoritesProvider>(
                                builder: (context, favoritesProvider, child) {
                                  final isFavorite = favoritesProvider.isFavorite(product['id']);
                                  return IconButton(
                                    padding: EdgeInsets.zero, // Reduce padding
                                    icon: Icon(
                                      isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: isFavorite ? Colors.red : Theme.of(context).colorScheme.primary,
                                    ),
                                    onPressed: () {
                                      if (isFavorite) {
                                        favoritesProvider.removeFavorite(product['id']);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${product['name']} removed from favorites!'),
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      } else {
                                        favoritesProvider.addFavorite(product['id']);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${product['name']} added to favorites!'),
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                              // New WhatsApp Icon
                              IconButton(
                                padding: EdgeInsets.zero, // Reduce padding
                                icon: Icon(Icons.message, color: Colors.green), // Using message icon and green color
                                onPressed: () async {
                                  final phoneNumber = '254113206481'; // Replace with your WhatsApp number
                                  final message = 'Hello, I would like to order the following product:\n' + 
                                      'Product: ${product['name']}\n' + 
                                      'Price: KES ${product['price'].toStringAsFixed(2)}\n' + 
                                      'Link: ${product['link']}';
                                  final whatsappUrl = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';

                                  if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
                                    await launchUrl(Uri.parse(whatsappUrl));
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Could not launch WhatsApp. Please ensure it is installed.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
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
