import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Set<String> _favoriteProductIds = {};

  Set<String> get favoriteProductIds => _favoriteProductIds;

  FavoritesProvider() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        fetchFavorites();
      } else {
        _favoriteProductIds.clear();
        notifyListeners();
      }
    });
  }

  Future<void> fetchFavorites() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final querySnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .get();

      _favoriteProductIds = querySnapshot.docs.map((doc) => doc['productId'] as String).toSet();
      notifyListeners();
    } catch (e) {
      print('Error fetching favorites: $e');
      // Optionally show a toast
    }
  }

  Future<void> addFavorite(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return; // User not logged in

    if (_favoriteProductIds.contains(productId)) return; // Already favorited

    try {
      // Check if it already exists to prevent duplicates in Firestore
      final existing = await _firestore.collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        await _firestore.collection('favorites').add({
          'userId': user.uid,
          'productId': productId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _favoriteProductIds.add(productId);
        notifyListeners();
      }
    } catch (e) {
      print('Error adding favorite: $e');
      // Optionally show a toast
    }
  }

  Future<void> removeFavorite(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return; // User not logged in

    if (!_favoriteProductIds.contains(productId)) return; // Not favorited

    try {
      final querySnapshot = await _firestore.collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await _firestore.collection('favorites').doc(querySnapshot.docs.first.id).delete();
        _favoriteProductIds.remove(productId);
        notifyListeners();
      }
    } catch (e) {
      print('Error removing favorite: $e');
      // Optionally show a toast
    }
  }

  bool isFavorite(String productId) {
    return _favoriteProductIds.contains(productId);
  }
}
