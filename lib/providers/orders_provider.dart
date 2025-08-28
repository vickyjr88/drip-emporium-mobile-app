import 'package:flutter/material.dart';
import '../services/data_repository.dart';
import '../models/order.dart';

class OrdersProvider with ChangeNotifier {
  final DataRepository _dataRepository = DataRepository();
  List<Order> _userOrders = [];
  List<Order> _allOrders = [];
  bool _isLoadingUserOrders = false;
  bool _isLoadingAllOrders = false;
  String? _userOrdersErrorMessage;
  String? _allOrdersErrorMessage;

  List<Order> get userOrders => _userOrders;
  List<Order> get allOrders => _allOrders;
  bool get isLoadingUserOrders => _isLoadingUserOrders;
  bool get isLoadingAllOrders => _isLoadingAllOrders;
  String? get userOrdersErrorMessage => _userOrdersErrorMessage;
  String? get allOrdersErrorMessage => _allOrdersErrorMessage;

  Future<void> fetchUserOrders(String uid) async {
    _isLoadingUserOrders = true;
    _userOrdersErrorMessage = null;
    notifyListeners();
    try {
      // Assuming fetchUserOrders in DataRepository returns List<Map<String, dynamic>>
      // and needs to be converted to List<Order>
      final fetchedOrders = await _dataRepository.fetchUserOrders(uid);
      _userOrders =
          fetchedOrders
              .map((data) => Order.fromMap(data, data['orderId']))
              .toList();
    } catch (e) {
      _userOrdersErrorMessage = 'Failed to fetch user orders: ${e.toString()}';
    } finally {
      _isLoadingUserOrders = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllOrders() async {
    _isLoadingAllOrders = true;
    _allOrdersErrorMessage = null;
    notifyListeners();
    try {
      // Assuming fetchAllOrders in DataRepository returns Map<String, dynamic> with 'orders' key
      final result = await _dataRepository.fetchAllOrders();
      _allOrders =
          (result['orders'] as List)
              .map((data) => Order.fromMap(data, data['orderId']))
              .toList();
    } catch (e) {
      _allOrdersErrorMessage = 'Failed to fetch all orders: ${e.toString()}';
    } finally {
      _isLoadingAllOrders = false;
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _dataRepository.updateOrderStatus(orderId, status);
      // Refresh relevant order lists after update
      // This might involve re-fetching or updating the local list
      // For simplicity, re-fetching all orders for now
      await fetchAllOrders();
      // If user orders are displayed, also refresh them
      // if (FirebaseAuth.instance.currentUser != null) {
      //   await fetchUserOrders(FirebaseAuth.instance.currentUser!.uid);
      // }
    } catch (e) {
      print('Error updating order status: $e');
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<Map<String, double>> getDailySales(
    DateTime date, {
    String? storeId,
  }) async {
    try {
      return await _dataRepository.getDailySalesStatistics(
        date,
        storeId: storeId,
      );
    } catch (e) {
      print('Error getting daily sales: $e');
      throw Exception('Failed to get daily sales: $e');
    }
  }

  Future<Map<String, double>> getWeeklySales(
    DateTime date, {
    String? storeId,
  }) async {
    try {
      return await _dataRepository.getWeeklySalesStatistics(
        date,
        storeId: storeId,
      );
    } catch (e) {
      print('Error getting weekly sales: $e');
      throw Exception('Failed to get weekly sales: $e');
    }
  }
}
