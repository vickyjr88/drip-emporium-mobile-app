import 'package:drip_emporium/services/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // New import
import 'package:google_sign_in/google_sign_in.dart'; // New import
 // New import
import 'package:drip_emporium/screens/login_screen.dart'; // New import
import 'package:drip_emporium/screens/signup_screen.dart'; // New import
import 'dart:async'; // New import

class UserDetailsScreen extends StatefulWidget {
  final Function(String email, String name, String mobileNumber, String address) onProceedToPayment;

  const UserDetailsScreen({super.key, required this.onProceedToPayment});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DataRepository _dataRepository = DataRepository();

  late StreamSubscription<User?> _authStateSubscription; // New

  @override
  void initState() {
    super.initState();
    _populateFields(); // Populate fields if user is logged in

    // Listen to auth state changes
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      _populateFields(); // Update fields based on new user state
      setState(() {}); // Rebuild UI
    });
  }

  void _populateFields() async {
    final user = _auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      _nameController.text = user.displayName ?? '';

      // Fetch extra user details from Firestore
      try {
        final userDoc = await _dataRepository.getUserDetails(user.uid);
        if (userDoc != null) {
          _mobileController.text = userDoc['mobileNumber'] ?? '';
          _addressController.text = userDoc['address'] ?? '';
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user details: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Clear fields if user signs out
      _emailController.clear();
      _nameController.clear();
      _mobileController.clear();
      _addressController.clear();
    }
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      _populateFields(); // Populate fields after successful sign-in
      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to sign in with Google. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _authStateSubscription.cancel(); // Cancel subscription
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Your Details'),
        actions: [
          // Logout button if user is logged in
          if (_auth.currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _auth.signOut();
                _emailController.clear();
                _nameController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signed out successfully!')),
                );
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView( // Changed to ListView to allow scrolling
            children: [
              TextFormField(
                controller: _emailController, // Use controller
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                // onSaved: (value) { _email = value!; }, // No longer needed with controller
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _nameController, // Use controller
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
                // onSaved: (value) { _name = value!; }, // No longer needed with controller
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _mobileController, // New field
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
                controller: _addressController, // New field
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
              const SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onProceedToPayment(_emailController.text, _nameController.text, _mobileController.text, _addressController.text);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                ),
                child: const Text(
                  'Proceed to Payment',
                  style: TextStyle(fontSize: 18.0, color: Colors.white),
                ),
              ),
              // Show Sign Out button if user is logged in
              if (false && _auth.currentUser != null) ...[ // Temporarily hide
                const SizedBox(height: 16.0), // Spacing between buttons
                ElevatedButton(
                  onPressed: () async {
                    await _auth.signOut();
                    _emailController.clear();
                    _nameController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Signed out successfully!')),
                    );
                    setState(() {}); // Rebuild to hide sign-in options
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary, // Different color for sign out
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                  ),
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(fontSize: 18.0, color: Colors.white),
                  ),
                ),
              ],
              const SizedBox(height: 32.0),
              const Divider(),
              const SizedBox(height: 16.0),
              // Hide sign-in options if user is logged in
              if (_auth.currentUser == null)
                Center(
                  child: Column(
                    children: [
                      const Text('Or sign in to pre-fill details:'),
                      const SizedBox(height: 16),
                      SizedBox( // New SizedBox for full width
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            UserCredential? userCredential = await _signInWithGoogle();
                            if (userCredential != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Signed in as ${userCredential.user!.displayName ?? userCredential.user!.email}')),
                              );
                              _populateFields(); // Populate fields after successful sign-in
                              setState(() {}); // Rebuild to hide sign-in options
                            }
                          },
                          icon: Image.asset('assets/images/google_logo.png', height: 24.0), // Placeholder for Google logo
                          label: const Text('Sign In with Google'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox( // New SizedBox for full width
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            ).then((_) => _populateFields()); // Populate fields when returning from login
                            setState(() {}); // Rebuild to hide sign-in options
                          },
                          child: const Text('Sign In with Email'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox( // New SizedBox for full width
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const SignUpScreen()),
                            ).then((_) => _populateFields()); // Populate fields when returning from signup
                            setState(() {}); // Rebuild to hide sign-in options
                          },
                          child: const Text('Sign Up with Email'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
