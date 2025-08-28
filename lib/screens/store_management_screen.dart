import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/store_provider.dart';
import '../models/store.dart';

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  Store? _editingStore;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);

      if (_editingStore == null) {
        // Add new store
        final newStore = Store(
          id: DateTime.now().toIso8601String(), // Simple unique ID for now
          name: _nameController.text,
          address: _addressController.text,
          phoneNumber: _phoneController.text,
          email: _emailController.text,
        );
        await storeProvider.addStore(newStore);
      } else {
        // Update existing store
        final updatedStore = Store(
          id: _editingStore!.id,
          name: _nameController.text,
          address: _addressController.text,
          phoneNumber: _phoneController.text,
          email: _emailController.text,
        );
        await storeProvider.updateStore(updatedStore);
        _editingStore = null; // Clear editing state
      }
      _clearForm();
      Navigator.of(context).pop(); // Close the dialog
    }
  }

  void _editStore(Store store) {
    setState(() {
      _editingStore = store;
      _nameController.text = store.name;
      _addressController.text = store.address;
      _phoneController.text = store.phoneNumber;
      _emailController.text = store.email;
    });
    _showStoreDialog();
  }

  void _deleteStore(String storeId) async {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    await storeProvider.deleteStore(storeId);
  }

  void _clearForm() {
    _nameController.clear();
    _addressController.clear();
    _phoneController.clear();
    _emailController.clear();
    setState(() {
      _editingStore = null;
    });
  }

  void _showStoreDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(_editingStore == null ? 'Add New Store' : 'Edit Store'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Store Name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a store name.';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an address.';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a phone number.';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an email.';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _clearForm();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _saveForm,
                child: Text(_editingStore == null ? 'Add' : 'Update'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Management'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showStoreDialog),
        ],
      ),
      body: Consumer<StoreProvider>(
        builder: (context, storeProvider, child) {
          if (storeProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (storeProvider.errorMessage != null) {
            return Center(child: Text('Error: ${storeProvider.errorMessage}'));
          }
          if (storeProvider.stores.isEmpty) {
            return const Center(
              child: Text('No stores added yet. Click + to add one.'),
            );
          }
          return ListView.builder(
            itemCount: storeProvider.stores.length,
            itemBuilder: (ctx, i) {
              final store = storeProvider.stores[i];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(store.name),
                  subtitle: Text(store.address),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editStore(store),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteStore(store.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
