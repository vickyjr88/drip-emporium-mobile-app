import 'package:drip_emporium/screens/all_users_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:drip_emporium/screens/orders_screen.dart'; // New import
import 'package:drip_emporium/screens/admin_orders_screen.dart'; // New import
import 'package:drip_emporium/screens/favorites_screen.dart'; // New import

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  bool _isSuperAdmin = false; // New state variable

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkIfSuperAdmin(); // Check admin status
  }

  Future<void> _checkIfSuperAdmin() async {
    if (currentUser == null) {
      setState(() {
        _isSuperAdmin = false;
      });
      return;
    }
    try {
      print('${currentUser!.uid}');
      final doc = await _firestore.collection('superAdmins').doc(currentUser!.uid).get();
      print(doc);
      setState(() {
        _isSuperAdmin = doc.exists;
      });
    } catch (e) {
      print('Error checking super admin status: $e');
      setState(() {
        _isSuperAdmin = false;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    if (currentUser == null) return;

    _displayNameController.text = currentUser!.displayName ?? '';
    _emailController.text = currentUser!.email ?? '';

    try {
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      if (doc.exists) {
        _mobileController.text = doc.data()?['mobileNumber'] ?? '';
        _addressController.text = doc.data()?['address'] ?? '';
      }
    } catch (e) {
      print('Error loading user profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load profile. Please check your internet connection.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveUserProfile() async {
    if (_formKey.currentState!.validate()) {
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to save your profile.')),
        );
        return;
      }

      try {
        await _firestore.collection('users').doc(currentUser!.uid).set({
          'mobileNumber': _mobileController.text,
          'address': _addressController.text,
          'email': currentUser!.email, // Store email for reference
          'displayName': currentUser!.displayName, // Store display name for reference
        }, SetOptions(merge: true)); // Merge to avoid overwriting other fields

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
      } catch (e) {
        print('Error saving user profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save profile. Please check your internet connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _addressController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                ),
                readOnly: true, // Make it read-only
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                readOnly: true, // Make it read-only
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your delivery address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              ListTile(
                leading: const Icon(Icons.receipt), // Icon for orders
                title: const Text('My Orders'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OrdersScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite), // Icon for favorites
                title: const Text('My Favorites'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                  );
                },
              ),
              // Conditionally display admin orders link
              if (_isSuperAdmin)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings), // Admin icon
                  title: const Text('View All Orders (Admin)'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminOrdersScreen()),
                    );
                  },
                ),
              if (_isSuperAdmin)
                ListTile(
                  leading: const Icon(Icons.people), // All users icon
                  title: const Text('View All Users (Admin)'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AllUsersScreen()),
                    );
                  },
                ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _saveUserProfile,
                child: const Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
