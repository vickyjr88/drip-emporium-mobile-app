import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_line.dart';

const _cartPrefsKey = 'de_cart_v1';

/// The shopping cart, rewritten against the real API's variant model.
///
/// Keyed by variantId, not productId -- two sizes of the same shoe are now
/// two separate lines, which the old productId-keyed Map could not express
/// at all. Discount/bargain/customerType are gone entirely: the backend
/// prices every line from the variant id at checkout, so a client-side price
/// override is not a feature to preserve here, it was the mechanism of a
/// real revenue bug (checkout charged the pre-discount total while
/// displaying/recording the post-discount one).
class CartProvider with ChangeNotifier {
  final List<CartLine> _lines = [];

  /// False until the initial SharedPreferences load has completed. Nothing
  /// persists before this is true, so a slow cold-start load can never
  /// silently overwrite a cart that was already saved from a previous
  /// session.
  bool ready = false;

  CartProvider() {
    _load();
  }

  List<CartLine> get lines => List.unmodifiable(_lines);

  /// Sum of quantities across all lines -- the old `itemCount` was
  /// `_items.length`, distinct lines only, which undercounted the badge the
  /// moment any line had quantity > 1.
  int get count => _lines.fold(0, (sum, line) => sum + line.quantity);

  num get subtotal => _lines.fold<num>(0, (sum, line) => sum + line.lineTotal);

  CartLine? _findByVariant(String variantId) {
    for (final line in _lines) {
      if (line.variantId == variantId) return line;
    }
    return null;
  }

  /// Adds a line, merging into an existing one for the same variant rather
  /// than creating a duplicate.
  void add(CartLine line, {int quantity = 1}) {
    final existing = _findByVariant(line.variantId);
    if (existing != null) {
      existing.quantity += quantity;
    } else {
      _lines.add(CartLine(
        variantId: line.variantId,
        productSlug: line.productSlug,
        name: line.name,
        size: line.size,
        sku: line.sku,
        priceKes: line.priceKes,
        imageUrl: line.imageUrl,
        quantity: quantity,
      ));
    }
    _persist();
    notifyListeners();
  }

  /// Removing at `<= 0` -- this is the `updateQuantity` the app was
  /// previously missing (only increase/decrease-by-one existed).
  void setQuantity(String variantId, int quantity) {
    if (quantity <= 0) {
      remove(variantId);
      return;
    }
    final existing = _findByVariant(variantId);
    if (existing == null) return;
    existing.quantity = quantity;
    _persist();
    notifyListeners();
  }

  void remove(String variantId) {
    _lines.removeWhere((line) => line.variantId == variantId);
    _persist();
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    if (!ready) return; // See the class doc: never persist before loaded.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartPrefsKey, jsonEncode(_lines.map((line) => line.toJson()).toList()));
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_cartPrefsKey);
      if (encoded != null) {
        final decoded = jsonDecode(encoded);
        if (decoded is List) {
          _lines
            ..clear()
            ..addAll(decoded.whereType<Map<String, dynamic>>().map(CartLine.fromJson));
        }
      }
    } catch (_) {
      // Corrupt JSON (or an old, structurally incompatible 'cartItems' blob
      // this key never reads) clears the cart rather than bricking the app
      // on every launch.
      _lines.clear();
    } finally {
      ready = true;
      notifyListeners();
    }
  }
}
