
import 'package:drip_emporium/screens/cart_screen.dart';
import 'package:drip_emporium/screens/profile_screen.dart';
import 'package:drip_emporium/services/payment_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drip_emporium/main.dart';


class BottomNavBarScreen extends StatefulWidget {
  final PaymentService paymentService;
  const BottomNavBarScreen({super.key, required this.paymentService});

  @override
  State<BottomNavBarScreen> createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      HomeScreen(paymentService: widget.paymentService),
      CartScreen(paymentService: widget.paymentService),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    if (index == 1) { // Index 1 is the "Message" item
      _launchWhatsApp();
    } else {
      setState(() {
        // Adjust index for the pages list
        if (index > 1) {
          _selectedIndex = index -1;
        } else {
          _selectedIndex = index;
        }
      });
    }
  }

  void _launchWhatsApp() async {
    const phoneNumber = '254113206481';
    const whatsappUrl = 'https://wa.me/$phoneNumber';

    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch WhatsApp. Please ensure it is installed.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Message',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
        currentIndex: _selectedIndex < 1 ? _selectedIndex : _selectedIndex + 1,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
