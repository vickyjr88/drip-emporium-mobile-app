import 'package:flutter/material.dart';
import 'package:drip_emporium/services/data_repository.dart';

class ProductsProvider with ChangeNotifier {
  final DataRepository _dataRepository;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  ProductsProvider(this._dataRepository) {
    fetchProducts();
  }

  List<Map<String, dynamic>> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _dataRepository.fetchProducts();
    } catch (e) {
      _errorMessage = 'Failed to load products. Please check your internet connection.';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
