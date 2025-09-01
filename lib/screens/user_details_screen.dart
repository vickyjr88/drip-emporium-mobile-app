import 'package:drip_emporium/models/customer.dart';
import 'package:drip_emporium/screens/manual_customer_entry_screen.dart';
import 'package:drip_emporium/services/data_repository.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:drip_emporium/screens/login_screen.dart';
import 'package:drip_emporium/screens/signup_screen.dart';
import 'dart:async';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class UserDetailsScreen extends StatefulWidget {
  final Function(String email, String name, String mobileNumber, String address)
      onProceedToPayment;

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

  late StreamSubscription<User?> _authStateSubscription;
  bool _isAttender = false;
  List<Customer> _customers = [];
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _populateFields();
    _checkIfAttender();
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      _populateFields();
      _checkIfAttender();
      setState(() {});
    });
  }

  void _checkIfAttender() async {
    final user = _auth.currentUser;
    if (user != null) {
      final attenderDoc = await _dataRepository.getAttender(user.uid);
      if (mounted) {
        setState(() {
          _isAttender = attenderDoc != null;
        });
        if (_isAttender) {
          _loadCustomers();
        }
      }
    }
  }

  void _loadCustomers() async {
    final customers = await _dataRepository.getCustomers();
    setState(() {
      _customers = customers;
    });
  }

  void _populateFields() async {
    final user = _auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      _nameController.text = user.displayName ?? '';

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
        return null;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      _populateFields();
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
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Your Details'),
        actions: [
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
      body: _isAttender ? _buildAttenderView() : _buildRegularView(),
    );
  }

  Widget _buildAttenderView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SearchAnchor(
            builder: (BuildContext context, SearchController controller) {
              return SearchBar(
                controller: controller,
                onTap: () {
                  controller.openView();
                },
                onChanged: (_) {
                  controller.openView();
                },
                leading: const Icon(Icons.search),
                hintText: 'Search for a customer',
              );
            },
            suggestionsBuilder:
                (BuildContext context, SearchController controller) {
              final keyword = controller.value.text;
              final filteredCustomers = _customers.where((customer) {
                return customer.name.toLowerCase().contains(keyword.toLowerCase()) ||
                    customer.email.toLowerCase().contains(keyword.toLowerCase());
              }).toList();

              return List<ListTile>.generate(filteredCustomers.length, (int index) {
                final customer = filteredCustomers[index];
                return ListTile(
                  title: Text(customer.name),
                  subtitle: Text(customer.email),
                  onTap: () {
                    setState(() {
                      _selectedCustomer = customer;
                      _emailController.text = customer.email;
                      _nameController.text = customer.name;
                      _mobileController.text = customer.phoneNumber;
                      _addressController.text = customer.address;
                      controller.closeView(customer.name);
                    });
                  },
                );
              });
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              if (await FlutterContacts.requestPermission()) {
                final contact = await FlutterContacts.openExternalPick();
                if (contact != null) {
                  setState(() {
                    _nameController.text = contact.displayName;
                    _mobileController.text = contact.phones.isNotEmpty ? contact.phones.first.number : '';
                    _emailController.text = contact.emails.isNotEmpty ? contact.emails.first.address : '';
                  });
                }
              }
            },
            icon: const Icon(Icons.contacts),
            label: const Text('Select from Contacts'),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ManualCustomerEntryScreen(),
                ),
              );
              if (result != null) {
                setState(() {
                  _emailController.text = result['email'];
                  _nameController.text = result['name'];
                  _mobileController.text = result['mobileNumber'];
                  _addressController.text = result['address'];
                });
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Enter Manually'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Form(
              key: _formKey,
              child: _buildFormFields(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegularView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: _buildFormFields(),
      ),
    );
  }

  Widget _buildFormFields() {
    return ListView(
      children: [
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(
              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
            ).hasMatch(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: _nameController,
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
        const SizedBox(height: 32.0),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onProceedToPayment(
                _emailController.text,
                _nameController.text,
                _mobileController.text,
                _addressController.text,
              );
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
        if (_auth.currentUser == null)
          Center(
            child: Column(
              children: [
                const SizedBox(height: 32.0),
                const Divider(),
                const SizedBox(height: 16.0),
                const Text('Or sign in to pre-fill details:'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      UserCredential? userCredential =
                          await _signInWithGoogle();
                      if (userCredential != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Signed in as ${userCredential.user!.displayName ?? userCredential.user!.email}',
                            ),
                          ),
                        );
                        _populateFields();
                        setState(() {});
                      }
                    },
                    icon: Image.asset(
                      'assets/images/google_logo.png',
                      height: 24.0,
                    ),
                    label: const Text('Sign In with Google'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          )
                          .then(
                            (_) => _populateFields(),
                          );
                      setState(() {});
                    },
                    child: const Text('Sign In with Email'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          )
                          .then(
                            (_) => _populateFields(),
                          );
                      setState(() {});
                    },
                    child: const Text('Sign Up with Email'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
