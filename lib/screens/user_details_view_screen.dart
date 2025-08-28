import 'package:drip_emporium/models/attender.dart';
import 'package:drip_emporium/models/store.dart';
import 'package:drip_emporium/providers/store_provider.dart';
import 'package:drip_emporium/services/data_repository.dart';
import 'package:drip_emporium/utils/phone_number_utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drip_emporium/widgets/attendant_form_dialog.dart';

class UserDetailsViewScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String userId;

  const UserDetailsViewScreen(
      {super.key, required this.userData, required this.userId});

  @override
  State<UserDetailsViewScreen> createState() => _UserDetailsViewScreenState();
}

class _UserDetailsViewScreenState extends State<UserDetailsViewScreen> {
  final DataRepository _dataRepository = DataRepository();
  bool _isAttendant = false;

  @override
  void initState() {
    super.initState();
    _checkIfAttendant();
  }

  Future<void> _checkIfAttendant() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('attenders')
          .where('email', isEqualTo: widget.userData['email'])
          .limit(1)
          .get();
      if (mounted) {
        setState(() {
          _isAttendant = querySnapshot.docs.isNotEmpty;
        });
      }
    } catch (e) {
      print('Error checking if user is attendant: $e');
    }
  }

  Future<void> _makeUserAttendant() async {
    final newAttender = await showDialog<Attender>(
      context: context,
      builder: (context) => AttendantFormDialog(userData: widget.userData),
    );

    if (newAttender != null) {
      try {
        await _dataRepository.addAttender(newAttender);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newAttender.name} is now an attendant.'),
            backgroundColor: Colors.green,
          ),
        );
        _checkIfAttendant(); // Re-check attendant status
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to make user an attendant: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showOrderDetailsDialog(Map<String, dynamic> orderData) {
    showDialog(
      context: context,
      builder: (context) {
        final items = orderData['items'] as List<dynamic>? ?? [];
        return AlertDialog(
          title: Text('Order Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order ID: ${orderData['orderId']}'),
                Text('Status: ${orderData['status'] ?? 'N/A'}'),
                Text('Total: KES ${(orderData['finalPrice'] ?? 0.0).toStringAsFixed(2)}'),
                const SizedBox(height: 10),
                const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...items.map((item) {
                  return ListTile(
                    title: Text(item['name'] ?? 'No name'),
                    subtitle: Text('Quantity: ${item['quantity']}'),
                    trailing: Text('KES ${(item['price'] ?? 0.0).toStringAsFixed(2)}'),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.userData['displayName'] ?? 'User Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userData['displayName'] ?? 'No display name',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: Text(widget.userData['email'] ?? 'No email'),
                      onTap: () =>
                          _launchURL('mailto:${widget.userData['email']}'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: Text(widget.userData['mobileNumber'] ?? 'No mobile number'),
                      onTap: () => _launchURL(
                          'tel:${sanitizePhoneNumber(widget.userData['mobileNumber'])}'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(widget.userData['address'] ?? 'No address'),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isAttendant ? null : _makeUserAttendant,
                        child: Text(_isAttendant ? 'Already an Attendant' : 'Make Attendant'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Orders:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('userId', isEqualTo: widget.userId)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Something went wrong');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('No orders found for this user.'));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final order = snapshot.data!.docs[index];
                      final orderData = order.data() as Map<String, dynamic>;
                      orderData['orderId'] = order.id;
                      final items = orderData['items'] as List<dynamic>? ?? [];
                      String title = 'Order with no items';
                      if (items.isNotEmpty) {
                        final firstItem = items.first;
                        title =
                            '${firstItem['name'] ?? 'No name'} x ${firstItem['quantity']}';
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          title: Text(title),
                          subtitle: Text(
                              'Status: ${orderData['status'] ?? 'N/A'}\nTotal: KES ${(orderData['finalPrice'] ?? orderData['totalAmount'] ?? 0.0).toStringAsFixed(2)}'),
                          isThreeLine: true,
                          onTap: () => _showOrderDetailsDialog(orderData),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }
}

class StoreSelectionDialog extends StatelessWidget {
  final List<Store> stores;

  const StoreSelectionDialog({super.key, required this.stores});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select a Store'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: stores.length,
          itemBuilder: (context, index) {
            final store = stores[index];
            return ListTile(
              title: Text(store.name),
              onTap: () {
                Navigator.of(context).pop(store);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}