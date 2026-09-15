import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/customer_auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../screens/login_screen.dart';

/// Toggles a product's favorite state, prompting sign-in first if the
/// shopper isn't logged in -- favorites are server-backed per customer, so
/// [FavoritesProvider.addFavorite] silently no-ops for a signed-out guest
/// otherwise, which looked like a broken button.
Future<void> toggleFavorite(BuildContext context, String productId) async {
  final auth = context.read<CustomerAuthProvider>();
  if (!auth.isSignedIn) {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    if (!context.mounted || !context.read<CustomerAuthProvider>().isSignedIn) return;
  }

  final favorites = context.read<FavoritesProvider>();
  if (favorites.isFavorite(productId)) {
    await favorites.removeFavorite(productId);
  } else {
    await favorites.addFavorite(productId);
  }
}
