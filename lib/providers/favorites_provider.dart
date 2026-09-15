import 'package:flutter/material.dart';
import '../models/favorite_product.dart';
import '../services/api_client.dart';
import '../services/favorites_repository.dart';
import 'customer_auth_provider.dart';

/// Rewired against the real backend's customer-JWT-guarded favorites
/// endpoints -- no local/guest fallback, since a favorite has no meaning
/// without an account (nothing to sync, no page shows it for a guest).
///
/// Kept the same public method names (isFavorite/addFavorite/removeFavorite)
/// as the old Firestore-backed version so home_screen.dart and
/// product_details_screen.dart need no changes at their call sites.
class FavoritesProvider with ChangeNotifier {
  FavoritesProvider(this._repository, this._auth) {
    // Load once at construction and again whenever sign-in state changes --
    // ChangeNotifier has no listen-to-another-notifier primitive, so this is
    // driven externally: see CustomerAuthProvider consumers calling
    // `refresh()` after login/logout, same pattern main.dart already uses to
    // wire auth into other providers.
    if (_auth.isSignedIn) {
      // ignore: discarded_futures
      refresh();
    }
  }

  final FavoritesRepository _repository;
  final CustomerAuthProvider _auth;

  List<FavoriteProduct> _items = [];
  bool _loading = false;
  final Set<String> _pending = {};

  List<FavoriteProduct> get items => _items;
  bool get isLoading => _loading;

  bool isFavorite(String productId) => _items.any((item) => item.productId == productId);

  Future<void> refresh() async {
    if (!_auth.isSignedIn) {
      _items = [];
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      _items = await _repository.fetchFavorites();
    } on ApiException {
      // Leave whatever was already loaded -- a favorites list disappearing
      // on a transient API error is worse than a stale one.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Signed-out is a no-op here, not an error -- FavoriteButton-equivalent
  /// call sites in this app route a signed-out tap to the login screen
  /// before ever calling this, matching the web storefront's own behavior.
  Future<void> addFavorite(String productId) async {
    if (!_auth.isSignedIn || _pending.contains(productId) || isFavorite(productId)) return;
    _pending.add(productId);
    try {
      await _repository.addFavorite(productId);
      await refresh(); // picks up the new item's name/image/price
    } catch (_) {
      // Failed add is simply not reflected -- nothing to revert.
    } finally {
      _pending.remove(productId);
    }
  }

  Future<void> removeFavorite(String productId) async {
    if (!_auth.isSignedIn || _pending.contains(productId) || !isFavorite(productId)) return;
    _pending.add(productId);
    // Optimistic removal -- a favorite toggle should feel instant.
    final previous = _items;
    _items = _items.where((item) => item.productId != productId).toList();
    notifyListeners();
    try {
      await _repository.removeFavorite(productId);
    } catch (_) {
      _items = previous; // revert on failure
      notifyListeners();
    } finally {
      _pending.remove(productId);
    }
  }
}
