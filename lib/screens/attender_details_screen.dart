import 'package:drip_emporium/models/store.dart';
import 'package:drip_emporium/providers/store_provider.dart';
import 'package:drip_emporium/screens/store_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drip_emporium/utils/phone_number_utils.dart';
import '../models/attender.dart';

class AttenderDetailsScreen extends StatelessWidget {
  final Attender attender;

  const AttenderDetailsScreen({super.key, required this.attender});

  Future<void> _makePhoneCall(String mobileNumber) async {
    final sanitizedNumber = sanitizeMobileNumber(mobileNumber);
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: sanitizedNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      print('Could not launch $launchUri');
    }
  }

  Future<void> _launchWhatsApp(String mobileNumber) async {
    final sanitizedNumber = sanitizeMobileNumber(mobileNumber);
    final Uri launchUri = Uri.parse('https://wa.me/$sanitizedNumber');
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      print('Could not launch $launchUri');
    }
  }

  Future<void> _sendEmail(String emailAddress) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      print('Could not launch $launchUri');
    }
  }

  void _showStoreDialog(BuildContext context, Store store) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(store.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Address: ${store.address}'),
              const SizedBox(height: 8),
              Text('Phone: ${store.mobileNumber}'),
              const SizedBox(height: 8),
              Text('Email: ${store.email}'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.phone, size: 30),
                    onPressed: () => _makePhoneCall(store.mobileNumber),
                  ),
                  IconButton(
                    icon: const Icon(Icons.message, size: 30, color: Colors.green),
                    onPressed: () => _launchWhatsApp(store.mobileNumber),
                  ),
                  IconButton(
                    icon: const Icon(Icons.email, size: 30),
                    onPressed: () => _sendEmail(store.email),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => StoreDetailsScreen(store: store),
                ),
              );
            },
            child: const Text('View Full Details'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attender Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${attender.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Email: ${attender.email}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Phone: ${attender.mobileNumber}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Role: ${attender.role}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Consumer<StoreProvider>(
              builder: (context, storeProvider, child) {
                final store = storeProvider.stores.firstWhere(
                  (s) => s.id == attender.storeId,
                  orElse: () => Store(
                    id: '',
                    name: 'Unknown Store',
                    address: '',
                    mobileNumber: '',
                    email: '',
                  ),
                );
                return ListTile(
                  title: const Text('Store'),
                  subtitle: Text(store.name),
                  trailing: const Icon(Icons.info_outline),
                  onTap: () {
                    if (store.id.isNotEmpty) {
                      _showStoreDialog(context, store);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.phone, size: 30),
                  onPressed: () => _makePhoneCall(attender.mobileNumber),
                ),
                IconButton(
                  icon: const Icon(Icons.message, size: 30, color: Colors.green), // WhatsApp icon
                  onPressed: () => _launchWhatsApp(attender.mobileNumber),
                ),
                IconButton(
                  icon: const Icon(Icons.email, size: 30),
                  onPressed: () => _sendEmail(attender.email),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
