import 'package:flutter/material.dart';
import '../models/store.dart';
import '../services/data_repository.dart';

class StoreProvider with ChangeNotifier {
  final DataRepository _dataRepository = DataRepository();
  List<Store> _stores = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Store> get stores => _stores;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  StoreProvider() {
    fetchStores();
  }

  Future<void> fetchStores() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _dataRepository.initDatabase();
      _stores = await _dataRepository.getStores();
    } catch (e) {
      _errorMessage = 'Failed to fetch stores: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addStore(Store store) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _dataRepository.addStore(store);
      await fetchStores(); // Refresh list after adding
    } catch (e) {
      _errorMessage = 'Failed to add store: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStore(Store store) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _dataRepository.updateStore(store);
      await fetchStores(); // Refresh list after updating
    } catch (e) {
      _errorMessage = 'Failed to update store: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteStore(String storeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _dataRepository.deleteStore(storeId);
      await fetchStores(); // Refresh list after deleting
    } catch (e) {
      _errorMessage = 'Failed to delete store: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}