import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drip_emporium/screens/cart_screen.dart';
import 'package:drip_emporium/screens/profile_screen.dart';
import 'package:drip_emporium/services/payment_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drip_emporium/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:drip_emporium/screens/login_screen.dart';
import '../screens/admin_dashboard_screen.dart';

class BottomNavBarScreen extends StatefulWidget {
  final PaymentService paymentService;
  const BottomNavBarScreen({super.key, required this.paymentService});

  @override
  State<BottomNavBarScreen> createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
  int _selectedIndex = 0;
  bool _isSuperAdmin = false;
  List<Widget> _pages = [];
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _checkIfSuperAdmin();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkIfSuperAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isSuperAdmin = false;
          _buildPages();
        });
      }
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('superAdmins')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          _isSuperAdmin = doc.exists;
          _buildPages();
        });
      }
    } catch (e) {
      print('Error checking super admin status: $e');
      if (mounted) {
        setState(() {
          _isSuperAdmin = false;
          _buildPages();
        });
      }
    }
  }

  void _buildPages() {
    _pages = <Widget>[
      HomeScreen(paymentService: widget.paymentService),
      CartScreen(paymentService: widget.paymentService),
      const ProfileScreen(),
      if (_isSuperAdmin) const AdminDashboardScreen(),
    ];
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      _launchWhatsApp();
      return;
    }

    int pageIndex = index;
    if (index > 1) {
      pageIndex = index - 1;
    }

    if (pageIndex == 2) { // Profile/Account tab
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }
    }

    setState(() {
      _selectedIndex = pageIndex;
    });
  }


  void _launchWhatsApp() async {
    const phoneNumber = '254113206481';
    const whatsappUrl = 'https://wa.me/$phoneNumber';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chat on WhatsApp'),
          content: Text.rich(
            TextSpan(
              text: 'Do you want to chat with ',
              children: [
                TextSpan(
                  text: 'Drip Emporium',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' on WhatsApp?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Chat'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not launch WhatsApp. Please ensure it is installed.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final navBarItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart),
        label: 'Cart',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.account_circle),
        label: 'Account',
      ),
      if (_isSuperAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
    ];

    int currentIndex = _selectedIndex;
    if (_selectedIndex > 0) {
      currentIndex = _selectedIndex + 1;
    }

    return Scaffold(
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: navBarItems,
        currentIndex: currentIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
