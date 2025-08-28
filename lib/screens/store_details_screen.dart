import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drip_emporium/utils/phone_number_utils.dart';
import '../models/store.dart';

class StoreDetailsScreen extends StatelessWidget {
  final Store store;

  const StoreDetailsScreen({super.key, required this.store});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final sanitizedNumber = sanitizePhoneNumber(phoneNumber);
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

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final sanitizedNumber = sanitizePhoneNumber(phoneNumber);
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
              'Name: ${store.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Address: ${store.address}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Phone: ${store.phoneNumber}',
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
                  onPressed: () => _makePhoneCall(store.phoneNumber),
                ),
                IconButton(
                  icon: const Icon(Icons.message, size: 30, color: Colors.green), // WhatsApp icon
                  onPressed: () => _launchWhatsApp(store.phoneNumber),
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
    );
  }
}
