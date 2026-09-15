import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drip_emporium/services/data_repository.dart';
import 'package:drip_emporium/providers/products_provider.dart';
import 'package:drip_emporium/providers/cart_provider.dart';
import 'package:drip_emporium/providers/favorites_provider.dart'; // New import
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart'; // New import
import 'package:firebase_auth/firebase_auth.dart'; // New import
import 'package:drip_emporium/screens/bottom_nav_bar_screen.dart';
import 'package:drip_emporium/providers/store_provider.dart';
import 'package:drip_emporium/providers/attender_provider.dart';
import 'package:drip_emporium/providers/orders_provider.dart';
import 'package:drip_emporium/config/api_config.dart';
import 'package:drip_emporium/services/api_client.dart';
import 'package:drip_emporium/services/customer_api.dart';
import 'package:drip_emporium/services/shop_repository.dart';
import 'package:drip_emporium/services/checkout_repository.dart';
import 'package:drip_emporium/services/favorites_repository.dart';
import 'package:drip_emporium/services/cart_lead_service.dart';
import 'package:drip_emporium/providers/customer_auth_provider.dart';
import 'package:drip_emporium/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase

  final dataRepository = DataRepository();
  await dataRepository.initDatabase();

  // The new backend auth, registered alongside the existing Firebase auth
  // for now -- additive, per the migration's step-by-step sequencing.
  // CustomerAuthProvider is constructed first so its tokenSupplier can be
  // wired into the ApiClient every later repository will share.
  late final CustomerAuthProvider customerAuth;
  final apiClient = ApiClient(
    baseUrl: ApiConfig.baseUrl,
    tokenSupplier: () => customerAuth.tokenSupplier(),
  );
  final customerApi = CustomerApi(apiClient);
  customerAuth = CustomerAuthProvider(customerApi);
  final shopRepository = ShopRepository(apiClient);
  final checkoutRepository = CheckoutRepository(apiClient);
  final favoritesRepository = FavoritesRepository(apiClient);
  final cartLeadService = CartLeadService(apiClient);

  runApp(
    MultiProvider(
      // Use MultiProvider for multiple providers
      providers: [
        ChangeNotifierProvider(
          create: (context) => ProductsProvider(shopRepository),
        ),
        ChangeNotifierProvider(
          create: (context) => CartProvider(),
        ), // New provider
        ChangeNotifierProvider(
          create: (context) => FavoritesProvider(favoritesRepository, customerAuth),
        ), // New provider
        ChangeNotifierProvider(
          create: (context) => StoreProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => AttenderProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => OrdersProvider(),
        ),
        ChangeNotifierProvider.value(value: customerAuth),
        Provider.value(value: shopRepository),
        Provider.value(value: checkoutRepository),
        Provider.value(value: favoritesRepository),
        Provider.value(value: cartLeadService),
        Provider.value(value: customerApi),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  // Changed to StatefulWidget
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
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri.toString());
      },
      onError: (err) {
        // Handle error
        print('Error receiving deep link: $err');
      },
    );
  }

  /// Payment completion no longer arrives via a custom URI scheme --
  /// Paystack's callback goes to a real web page
  /// (dripemporium.store/checkout/complete), which PaymentWebViewScreen
  /// intercepts directly inside the checkout flow instead. This handler is
  /// kept as the place future product deep links (dripemporium.store/shop/:slug)
  /// would be wired in, per the migration plan -- app_links itself stays a
  /// dependency for that reason, just not for payment anymore.
  void _handleDeepLink(String link) {
    // No routes recognised yet.
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drip Emporium',
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: const BottomNavBarScreen(),
    );
  }
}
