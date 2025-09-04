import 'package:drip_emporium/models/attender.dart';
import 'package:drip_emporium/providers/attender_provider.dart';
import 'package:drip_emporium/screens/attender_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drip_emporium/utils/phone_number_utils.dart';
import '../models/store.dart';

class StoreDetailsScreen extends StatelessWidget {
  final Store store;

  const StoreDetailsScreen({super.key, required this.store});

  Future<void> _makePhoneCall(String mobileNumber) async {
    final sanitizedNumber = sanitizeMobileNumber(mobileNumber);
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: sanitizedNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Fallback for web or other platforms where tel: might not work directly
      // You might want to show a dialog or copy to clipboard
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

  void _showAttendantDialog(BuildContext context, Attender attendant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(attendant.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Email: ${attendant.email}'),
              const SizedBox(height: 8),
              Text('Phone: ${attendant.mobileNumber}'),
              const SizedBox(height: 8),
              Text('Role: ${attendant.role}'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.phone, size: 30),
                    onPressed: () => _makePhoneCall(attendant.mobileNumber),
                  ),
                  IconButton(
                    icon: const Icon(Icons.message, size: 30, color: Colors.green),
                    onPressed: () => _launchWhatsApp(attendant.mobileNumber),
                  ),
                  IconButton(
                    icon: const Icon(Icons.email, size: 30),
                    onPressed: () => _sendEmail(attendant.email),
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
                  builder: (context) => AttenderDetailsScreen(attender: attendant),
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
        title: const Text('Store Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${store.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Address: ${store.address}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Phone: ${store.mobileNumber}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Email: ${store.email}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.phone, size: 30),
                  onPressed: () => _makePhoneCall(store.mobileNumber),
                ),
                IconButton(
                  icon: const Icon(Icons.message, size: 30, color: Colors.green), // WhatsApp icon
                  onPressed: () => _launchWhatsApp(store.mobileNumber),
                ),
                IconButton(
                  icon: const Icon(Icons.email, size: 30),
                  onPressed: () => _sendEmail(store.email),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Attendants:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Consumer<AttenderProvider>(
                builder: (context, attenderProvider, child) {
                  final attendants = attenderProvider.attenders
                      .where((att) => att.storeId == store.id)
                      .toList();
                  if (attendants.isEmpty) {
                    return const Text('No attendants found for this store.');
                  }
                  return ListView.builder(
                    itemCount: attendants.length,
                    itemBuilder: (context, index) {
                      final attendant = attendants[index];
                      return ListTile(
                        title: Text(attendant.name),
                        subtitle: Text(attendant.role),
                        trailing: const Icon(Icons.info_outline),
                        onTap: () {
                          _showAttendantDialog(context, attendant);
                        },
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
}
