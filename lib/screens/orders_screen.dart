import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:drip_emporium/services/data_repository.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DataRepository _dataRepository = DataRepository();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please log in to view your orders.';
      });
      return;
    }

    try {
      final fetchedOrders = await _dataRepository.fetchUserOrders(user.uid, limit: 20);
      setState(() {
        _orders = fetchedOrders;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _orders.isEmpty
                  ? const Center(child: Text('No orders found.'))
                  : ListView.builder(
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Amount: KES ${order['totalAmount']?.toStringAsFixed(2) ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Status: ${order['status'] ?? 'N/A'}'),
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
