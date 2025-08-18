import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Follow Drip Emporium',
              style: Theme
                  .of(context)
                  .textTheme
                  .headlineSmall,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.alternate_email), // Generic icon for X
            title: const Text('X - @emporiumdrip'),
            onTap: () => _launchUrl('https://x.com/emporiumdrip'),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt), // Generic icon for Instagram
            title: const Text('Instagram - @emporium_drip'),
            onTap: () => _launchUrl('https://instagram.com/emporium_drip'),
          ),
          ListTile(
            leading: const Icon(Icons.facebook), // Generic icon for Facebook
            title: const Text('Facebook - Drip Emporium'),
            onTap: () => _launchUrl('https://facebook.com/DripEmporium'),
          ),
          ListTile(
            leading: const Icon(Icons.tiktok), // Generic icon for TikTok
            title: const Text('TikTok - @drip.emporium'),
            onTap: () => _launchUrl('https://tiktok.com/@drip.emporium'),
          ),
          ListTile(
            leading: const Icon(Icons.message), // WhatsApp icon
            title: const Text('WhatsApp - 254113206481'),
            onTap: () => _launchUrl('https://wa.me/254113206481'),
          ),
          ListTile(
            leading: const Icon(Icons.phone), // Phone icon
            title: const Text('Calls/SMS - 254722617418'),
            onTap: () => _launchUrl('tel:+254722617418'),
          ),
        ],
      ),
    );
  }
}
