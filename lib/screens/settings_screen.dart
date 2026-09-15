import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/section_header.dart';

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
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SectionHeader(title: 'Follow Drip Emporium'),
          _SocialTile(
            icon: const FaIcon(FontAwesomeIcons.xTwitter),
            label: 'X - @dripemporium',
            onTap: () => _launchUrl('https://x.com/dripemporium'),
          ),
          _SocialTile(
            icon: const FaIcon(FontAwesomeIcons.instagram),
            label: 'Instagram - @emporium_drip',
            onTap: () => _launchUrl('https://instagram.com/emporium_drip'),
          ),
          _SocialTile(
            icon: const FaIcon(FontAwesomeIcons.threads),
            label: 'Threads - @emporium_drip',
            onTap: () => _launchUrl('https://www.threads.net/@emporium_drip'),
          ),
          _SocialTile(
            icon: const FaIcon(FontAwesomeIcons.facebook),
            label: 'Facebook - Drip Emporium',
            onTap: () => _launchUrl('https://facebook.com/dripemp'),
          ),
          _SocialTile(
            icon: const FaIcon(FontAwesomeIcons.tiktok),
            label: 'TikTok - @drip.emporium',
            onTap: () => _launchUrl('https://tiktok.com/@drip.emporium'),
          ),
          _SocialTile(
            icon: const Icon(Icons.language_outlined),
            label: 'Website - dripemporium.store',
            onTap: () => _launchUrl('https://dripemporium.store'),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Contact'),
          _SocialTile(
            icon: const FaIcon(FontAwesomeIcons.whatsapp),
            label: 'WhatsApp - 254113206481',
            iconColor: AppColors.go,
            onTap: () => _launchUrl('https://wa.me/254113206481'),
          ),
          _SocialTile(
            icon: const Icon(Icons.call_outlined),
            label: 'Calls/SMS - 254722617418',
            onTap: () => _launchUrl('tel:+254722617418'),
          ),
        ],
      ),
    );
  }
}

class _SocialTile extends StatelessWidget {
  const _SocialTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconTheme(
        data: IconThemeData(color: iconColor ?? AppColors.royal, size: 22),
        child: icon,
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}
