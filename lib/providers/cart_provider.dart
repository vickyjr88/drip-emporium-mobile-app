import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // New import
import 'dart:convert'; // For JSON encoding/decoding
import '../models/customer.dart';

class CartProvider with ChangeNotifier {
  final Map<String, Map<String, dynamic>> _items = {};
  CustomerType _customerType = CustomerType.client; // Default customer type
  double _discountPercentage = 0.0;
  double _bargainAmount = 0.0;

  CartProvider() {
    _loadCartFromPrefs(); // Load cart when provider is initialized
  }

  Map<String, Map<String, dynamic>> get items => _items;

  int get itemCount => _items.length;

  CustomerType get customerType => _customerType;
  double get discountPercentage => _discountPercentage;
  double get bargainAmount => _bargainAmount;

  void setCustomerType(CustomerType type) {
    _customerType = type;
    notifyListeners();
  }

  void applyDiscount(double percentage) {
    if (percentage >= 0 && percentage <= 100) {
      _discountPercentage = percentage / 100.0;
      _bargainAmount = 0.0; // Clear bargain if discount is applied
      notifyListeners();
    }
  }

  void setBargainAmount(double amount) {
    if (amount >= 0) {
      _bargainAmount = amount;
      _discountPercentage = 0.0; // Clear discount if bargain is applied
      notifyListeners();
    }
  }

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, item) {
      total += item['price'] * item['quantity'];
    });
    return total;
  }

  double get finalPrice {
    double calculatedPrice = totalAmount;
    if (_discountPercentage > 0) {
      calculatedPrice = calculatedPrice * (1 - _discountPercentage);
    } else if (_bargainAmount > 0) {
      calculatedPrice =
          _bargainAmount; // If bargain is set, it overrides other pricing
    }
    return calculatedPrice;
  }

  void addItem(
    String productId,
    String name,
    double price,
    String imageUrl,
    String link,
  ) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existingItem) => {
          'id': existingItem['id'],
          'name': existingItem['name'],
          'price': existingItem['price'],
          'imageUrl': existingItem['imageUrl'],
          'quantity': existingItem['quantity'] + 1,
        },
      );
    } else {
      _items.putIfAbsent(
        productId,
        () => {
          'id': productId,
          'name': name,
          'price': price,
          'imageUrl': imageUrl,
          'quantity': 1,
        },
      );
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
      _items.update(
        productId,
        (existingItem) => {
          ...existingItem, // Keep existing properties
          'quantity': existingItem['quantity'] + 1,
        },
      );
      _saveCartToPrefs();
      notifyListeners();
    }
  }

  void decreaseItemQuantity(String productId) {
    if (_items.containsKey(productId)) {
      if (_items[productId]!['quantity'] > 1) {
        _items.update(
          productId,
          (existingItem) => {
            ...existingItem, // Keep existing properties
            'quantity': existingItem['quantity'] - 1,
          },
        );
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
    final cartData = {
      'items': _items,
      'customerType': _customerType.toString().split('.').last,
      'discountPercentage': _discountPercentage,
      'bargainAmount': _bargainAmount,
    };
    final String encodedMap = json.encode(cartData);
    await prefs.setString('cartItems', encodedMap);
  }

  Future<void> _loadCartFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('cartItems')) {
      final String? encodedMap = prefs.getString('cartItems');
      if (encodedMap != null) {
        final Map<String, dynamic> decodedData = json.decode(encodedMap);
        _items.clear(); // Clear existing items before loading
        (decodedData['items'] as Map<String, dynamic>).forEach((key, value) {
          _items[key] = Map<String, dynamic>.from(value);
        });
        _customerType = CustomerType.values.firstWhere(
          (e) =>
              e.toString() ==
              'CustomerType.' + (decodedData['customerType'] ?? 'client'),
          orElse: () => CustomerType.client,
        );
        _discountPercentage =
            (decodedData['discountPercentage'] ?? 0.0).toDouble();
        _bargainAmount = (decodedData['bargainAmount'] ?? 0.0).toDouble();
        notifyListeners();
      }
    }
  }
}
