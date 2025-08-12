import 'package:flutter/material.dart';
import 'package:drip_emporium/services/data_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For DocumentSnapshot

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final DataRepository _dataRepository = DataRepository();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  final int _perPage = 10; // Items per page

  final List<String> _orderStatuses = ['pending', 'initiated', 'verifying', 'successful', 'failed', 'shipped', 'delivered', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _fetchAllOrders();
  }

  Future<void> _fetchAllOrders() async {
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _dataRepository.fetchAllOrders(limit: _perPage, startAfter: _lastDocument);
      setState(() {
        _orders.addAll(result['orders']);
        _lastDocument = result['lastDocument'];
        _hasMore = result['hasMore'];
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load orders: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _dataRepository.updateOrderStatusAdmin(orderId, newStatus);
      setState(() {
        // Update the status in the local list to reflect the change
        final index = _orders.indexWhere((order) => order['orderId'] == orderId);
        if (index != -1) {
          _orders[index]['status'] = newStatus;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order $orderId status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order status: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders (Admin)'),
      ),
      body: _isLoading && _orders.isEmpty // Show loading indicator only if no orders are loaded yet
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _orders.isEmpty
                  ? const Center(child: Text('No orders found.'))
                  : ListView.builder(
                      itemCount: _orders.length + (_hasMore ? 1 : 0), // Add 1 for loading indicator
                      itemBuilder: (context, index) {
                        if (index == _orders.length) {
                          if (_isLoading) {
                            return const Center(child: CircularProgressIndicator());
                          } else {
                            _fetchAllOrders(); // Load more data
                            return const Center(child: CircularProgressIndicator()); // Show while loading
                          }
                        }

                        final order = _orders[index];
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Order ID: ${order['orderId'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('User ID: ${order['userId'] ?? 'N/A'}'),
                                Text('Email: ${order['email'] ?? 'N/A'}'),
                                Text('Name: ${order['name'] ?? 'N/A'}'),
                                Text('Mobile: ${order['mobileNumber'] ?? 'N/A'}'),
                                Text('Address: ${order['address'] ?? 'N/A'}'),
                                Text('Total Amount: KES ${order['totalAmount']?.toStringAsFixed(2) ?? 'N/A'}'),
                                Row(
                                  children: [
                                    const Text('Status: '),
                                    DropdownButton<String>(
                                      value: order['status'] ?? _orderStatuses.first,
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          _updateOrderStatus(order['orderId'], newValue);
                                        }
                                      },
                                      items: _orderStatuses.map<DropdownMenuItem<String>>((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                                // Display items in the order
                                if (order['items'] != null && order['items'] is List)
                                  ...order['items'].map<Widget>((item) {
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                                      child: Text('- ${item['name']} x ${item['quantity']} (KES ${item['price']?.toStringAsFixed(2)}) '),
                                    );
                                  }).toList(),
                                Text('Order Date: ${order['timestamp'] != null ? (order['timestamp'].toDate()).toLocal().toString().split('.')[0] : 'N/A'}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
