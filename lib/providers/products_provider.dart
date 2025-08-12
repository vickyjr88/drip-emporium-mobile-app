import 'package:flutter/material.dart';
import 'package:drip_emporium/services/data_repository.dart';

class ProductsProvider with ChangeNotifier {
  final DataRepository _dataRepository;
  List<Map<String, dynamic>> _products = []; // This will hold the filtered products
  List<Map<String, dynamic>> _allProducts = []; // This will hold all fetched products
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = ''; // New search query

  ProductsProvider(this._dataRepository) {
    fetchProducts();
  }

  List<Map<String, dynamic>> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // New method to set search query
  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase(); // Store in lowercase for case-insensitive search
    _filterProducts(); // Filter products based on new query
    notifyListeners();
  }

  // Helper method to filter products
  void _filterProducts() {
    if (_searchQuery.isEmpty) {
      _products = List.from(_allProducts); // If no query, show all products
    } else {
      _products = _allProducts.where((product) {
        final productName = product['name']?.toLowerCase() ?? '';
        return productName.contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allProducts = await _dataRepository.fetchProducts(); // Fetch all products
      _filterProducts(); // Filter them immediately
    } catch (e) {
      _errorMessage = 'Failed to load products. Please check your internet connection.';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
