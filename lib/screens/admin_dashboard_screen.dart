import 'package:drip_emporium/models/attender.dart';
import 'package:drip_emporium/screens/admin_orders_screen.dart';
import 'package:drip_emporium/screens/all_users_screen.dart';
import 'package:flutter/material.dart';
import '../screens/store_management_screen.dart';
import '../screens/attender_management_screen.dart';
import '../screens/sales_statistics_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _updateExistingOrders(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Updating orders...'),
            ],
          ),
        );
      },
    );

    try {
      final attenderQuery = await FirebaseFirestore.instance
          .collection('attenders')
          .where('email', isEqualTo: 'vickyjr88@gmail.com')
          .limit(1)
          .get();

      if (attenderQuery.docs.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default attender not found.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final attender = Attender.fromFirestore(attenderQuery.docs.first);
      final attenderId = attender.id;
      final storeId = attender.storeId;

      final ordersSnapshot =
          await FirebaseFirestore.instance.collection('orders').get();

      final batch = FirebaseFirestore.instance.batch();

      for (final orderDoc in ordersSnapshot.docs) {
        batch.update(orderDoc.reference, {
          'attenderId': attenderId,
          'storeId': storeId,
        });
      }

      await batch.commit();

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All orders have been updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('View All Orders'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const AdminOrdersScreen(),
                  ),
                );
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: const Icon(Icons.people_alt_outlined),
              title: const Text('View All Users'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const AllUsersScreen(),
                  ),
                );
              },
            ),
          ),
          // Add more admin options here as needed
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _updateExistingOrders(context),
            child: const Text('Update Existing Orders'),
          ),
        ],
      ),
    );
  }
}
