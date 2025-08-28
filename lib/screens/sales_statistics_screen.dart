import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/orders_provider.dart';
import 'package:intl/intl.dart';

class SalesStatisticsScreen extends StatefulWidget {
  const SalesStatisticsScreen({super.key});

  @override
  State<SalesStatisticsScreen> createState() => _SalesStatisticsScreenState();
}

class _SalesStatisticsScreenState extends State<SalesStatisticsScreen> {
  DateTime _selectedDate = DateTime.now();
  double _dailySales = 0.0;
  double _weeklySales = 0.0;
  bool _isLoadingDaily = false;
  bool _isLoadingWeekly = false;
  String? _dailyErrorMessage;
  String? _weeklyErrorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSalesData();
  }

  Future<void> _fetchSalesData() async {
    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);

    setState(() {
      _isLoadingDaily = true;
      _isLoadingWeekly = true;
      _dailyErrorMessage = null;
      _weeklyErrorMessage = null;
    });

    try {
      final dailyResult = await ordersProvider.getDailySales(_selectedDate);
      setState(() {
        _dailySales = dailyResult['totalSales'] ?? 0.0;
      });
    } catch (e) {
      setState(() {
        _dailyErrorMessage = 'Failed to fetch daily sales: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoadingDaily = false;
      });
    }

    try {
      final weeklyResult = await ordersProvider.getWeeklySales(_selectedDate);
      setState(() {
        _weeklySales = weeklyResult['totalSales'] ?? 0.0;
      });
    } catch (e) {
      setState(() {
        _weeklyErrorMessage = 'Failed to fetch weekly sales: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoadingWeekly = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchSalesData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales Statistics')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Selected Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Sales',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _isLoadingDaily
                        ? const Center(child: CircularProgressIndicator())
                        : _dailyErrorMessage != null
                        ? Text(
                          'Error: ${_dailyErrorMessage!}',
                          style: const TextStyle(color: Colors.red),
                        )
                        : Text(
                          'Total: KES ${_dailySales.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.green,
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weekly Sales',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _isLoadingWeekly
                        ? const Center(child: CircularProgressIndicator())
                        : _weeklyErrorMessage != null
                        ? Text(
                          'Error: ${_weeklyErrorMessage!}',
                          style: const TextStyle(color: Colors.red),
                        )
                        : Text(
                          'Total: KES ${_weeklySales.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.green,
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
