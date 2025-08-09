import 'package:flutter/material.dart';

class CartProvider with ChangeNotifier {
  final Map<String, Map<String, dynamic>> _items = {};

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
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
