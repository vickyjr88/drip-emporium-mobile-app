import 'package:flutter/material.dart';
import '../screens/store_management_screen.dart';
import '../screens/attender_management_screen.dart';
import '../screens/sales_statistics_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Manage Stores'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const StoreManagementScreen(),
                  ),
                );
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Manage Attenders'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const AttenderManagementScreen(),
                  ),
                );
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('View Sales Statistics'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const SalesStatisticsScreen(),
                  ),
                );
              },
            ),
          ),
          // Add more admin options here as needed
        ],
      ),
    );
  }
}
