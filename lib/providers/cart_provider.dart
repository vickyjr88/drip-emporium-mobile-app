import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // New import
import 'dart:convert'; // For JSON encoding/decoding

class CartProvider with ChangeNotifier {
  final Map<String, Map<String, dynamic>> _items = {};

  CartProvider() {
    _loadCartFromPrefs(); // Load cart when provider is initialized
  }

  Map<String, Map<String, dynamic>> get items => _items;

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, item) {
      total += item['price'] * item['quantity'];
    });
    return total;
  }

  void addItem(
    String productId,
    String name,
    double price,
    String imageUrl,
    String link,
  ) {
    if (_items.containsKey(productId)) {
      _items.update(productId, (existingItem) => {
        'id': existingItem['id'],
        'name': existingItem['name'],
        'price': existingItem['price'],
        'imageUrl': existingItem['imageUrl'],
        'quantity': existingItem['quantity'] + 1,
      });
    } else {
      _items.putIfAbsent(productId, () => {
        'id': productId,
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
        'quantity': 1,
      });
    }
    _saveCartToPrefs(); // Save cart after adding item
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    _saveCartToPrefs(); // Save cart after removing item
    notifyListeners();
  }

  void increaseItemQuantity(String productId) {
    if (_items.containsKey(productId)) {
      _items.update(productId, (existingItem) => {
        ...existingItem, // Keep existing properties
        'quantity': existingItem['quantity'] + 1,
      });
      _saveCartToPrefs();
      notifyListeners();
    }
  }

  void decreaseItemQuantity(String productId) {
    if (_items.containsKey(productId)) {
      if (_items[productId]!['quantity'] > 1) {
        _items.update(productId, (existingItem) => {
          ...existingItem, // Keep existing properties
          'quantity': existingItem['quantity'] - 1,
        });
      } else {
        _items.remove(productId); // Remove if quantity becomes 0
      }
      _saveCartToPrefs();
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _saveCartToPrefs(); // Save cart after clearing
    notifyListeners();
  }

  // New methods for persistence
  Future<void> _saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedMap = json.encode(_items);
    await prefs.setString('cartItems', encodedMap);
  }

  Future<void> _loadCartFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('cartItems')) {
      final String? encodedMap = prefs.getString('cartItems');
      if (encodedMap != null) {
        final Map<String, dynamic> decodedMap = json.decode(encodedMap);
        _items.clear(); // Clear existing items before loading
        decodedMap.forEach((key, value) {
          _items[key] = Map<String, dynamic>.from(value);
        });
        notifyListeners();
      }
    }
  }
}
