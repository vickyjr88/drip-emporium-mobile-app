import 'package:flutter/material.dart';
import '../models/attender.dart';
import '../services/data_repository.dart';

class AttenderProvider with ChangeNotifier {
  final DataRepository _dataRepository = DataRepository();
  List<Attender> _attenders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Attender> get attenders => _attenders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AttenderProvider() {
    _fetchAttenders();
  }

  Future<void> _fetchAttenders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _attenders = await _dataRepository.getAttenders();
    } catch (e) {
      _errorMessage = 'Failed to fetch attenders: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAttender(Attender attender) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _dataRepository.addAttender(attender);
      await _fetchAttenders(); // Refresh list after adding
    } catch (e) {
      _errorMessage = 'Failed to add attender: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAttender(Attender attender) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _dataRepository.updateAttender(attender);
      await _fetchAttenders(); // Refresh list after updating
    } catch (e) {
      _errorMessage = 'Failed to update attender: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAttender(String attenderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _dataRepository.deleteAttender(attenderId);
      await _fetchAttenders(); // Refresh list after deleting
    } catch (e) {
      _errorMessage = 'Failed to delete attender: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
