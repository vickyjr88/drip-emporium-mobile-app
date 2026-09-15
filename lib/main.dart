import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drip_emporium/providers/products_provider.dart';
import 'package:drip_emporium/providers/cart_provider.dart';
import 'package:drip_emporium/providers/favorites_provider.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:drip_emporium/screens/bottom_nav_bar_screen.dart';
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
      debugPrint('Failed to get initial link.');
    }

    // Listen for incoming links while the app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri.toString());
      },
      onError: (err) {
        debugPrint('Error receiving deep link: $err');
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
