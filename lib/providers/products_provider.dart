import 'package:flutter/material.dart';
import 'package:drip_emporium/services/data_repository.dart';

import 'package:flutter/material.dart';
import 'package:drip_emporium/services/data_repository.dart';

class ProductsProvider with ChangeNotifier {
  final DataRepository _dataRepository;
  List<Map<String, dynamic>> _products = []; // This will hold the filtered products
  List<Map<String, dynamic>> _allProducts = []; // This will hold all fetched products
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = ''; // New search query
  String _selectedStore = 'Drip Emporium'; // Default selected store
  Set<String> _allStores = {}; // To store unique store names

  ProductsProvider(this._dataRepository) {
    print('ProductsProvider constructor called.');
    fetchProducts();
  }

  List<Map<String, dynamic>> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedStore => _selectedStore;
  List<String> get allStores => _allStores.toList();

  // New method to set search query
  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase(); // Store in lowercase for case-insensitive search
    _filterProducts(); // Filter products based on new query
    notifyListeners();
  }

  // New method to set selected store
  void setSelectedStore(String store) {
    _selectedStore = store;
    _filterProducts(); // Filter products based on new store
    notifyListeners();
  }

  // Helper method to filter products
  void _filterProducts() {
    List<Map<String, dynamic>> filteredBySearch = [];

    if (_searchQuery.isEmpty) {
      filteredBySearch = List.from(_allProducts); // If no query, show all products
    } else {
      filteredBySearch = _allProducts.where((product) {
        final productName = product['name']?.toLowerCase() ?? '';
        return productName.contains(_searchQuery);
      }).toList();
    }

    // Further filter by selected store
    if (_selectedStore == 'All Stores') {
      _products = filteredBySearch;
    } else {
      _products = filteredBySearch.where((product) {
        final productStore = product['stores']?.toLowerCase() ?? '';
        return productStore == _selectedStore.toLowerCase();
      }).toList();
    }
  }

  Future<void> fetchProducts() async {
    print('fetchProducts() called. isLoading: $_isLoading, errorMessage: $_errorMessage');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Attempting to fetch from DataRepository...');
      _allProducts = await _dataRepository.fetchProducts(); // Fetch all products
      print('Fetched ${_allProducts.length} products from DataRepository.');
      
      // Populate unique store names
      _allStores.clear();
      _allStores.add('All Stores'); // Add an option to view all stores
      for (var product in _allProducts) {
        final store = product['stores'];
        if (store != null) {
          _allStores.add(store);
        }
      }

      _filterProducts(); // Filter them immediately
    } catch (e) {
      _errorMessage = 'Failed to load products. Please check your internet connection.';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      print('fetchProducts() finished. isLoading: $_isLoading');
      notifyListeners();
    }
  }
}
