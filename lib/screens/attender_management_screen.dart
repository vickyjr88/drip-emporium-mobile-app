import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attender_provider.dart';
import '../models/attender.dart';
import '../providers/store_provider.dart';
import '../models/store.dart';

class AttenderManagementScreen extends StatefulWidget {
  const AttenderManagementScreen({super.key});

  @override
  State<AttenderManagementScreen> createState() =>
      _AttenderManagementScreenState();
}

class _AttenderManagementScreenState extends State<AttenderManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();

  Attender? _editingAttender;
  Store? _selectedStore;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final attenderProvider = Provider.of<AttenderProvider>(
        context,
        listen: false,
      );

      if (_editingAttender == null) {
        // Add new attender
        final newAttender = Attender(
          id: DateTime.now().toIso8601String(), // Simple unique ID for now
          name: _nameController.text,
          email: _emailController.text,
          storeId: _selectedStore!.id,
          role: _roleController.text,
        );
        await attenderProvider.addAttender(newAttender);
      } else {
        // Update existing attender
        final updatedAttender = Attender(
          id: _editingAttender!.id,
          name: _nameController.text,
          email: _emailController.text,
          storeId: _selectedStore!.id,
          role: _roleController.text,
        );
        await attenderProvider.updateAttender(updatedAttender);
        _editingAttender = null; // Clear editing state
      }
      _clearForm();
      Navigator.of(context).pop(); // Close the dialog
    }
  }

  void _editAttender(Attender attender) {
    setState(() {
      _editingAttender = attender;
      _nameController.text = attender.name;
      _emailController.text = attender.email;
      _roleController.text = attender.role;
      // Find the store and pre-select it
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      _selectedStore = storeProvider.stores.firstWhere(
        (store) => store.id == attender.storeId,
        orElse: () => storeProvider.stores.first, // Fallback to first store if not found
      );
    });
    _showAttenderDialog();
  }

  void _deleteAttender(String attenderId) async {
    final attenderProvider = Provider.of<AttenderProvider>(
      context,
      listen: false,
    );
    await attenderProvider.deleteAttender(attenderId);
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _roleController.clear();
    setState(() {
      _editingAttender = null;
      _selectedStore = null;
    });
  }

  void _showAttenderDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              _editingAttender == null ? 'Add New Attender' : 'Edit Attender',
            ),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Attender Name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an attender name.';
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
                    Consumer<StoreProvider>(
                      builder: (context, storeProvider, child) {
                        if (storeProvider.isLoading) {
                          return const CircularProgressIndicator();
                        }
                        if (storeProvider.stores.isEmpty) {
                          return const Text('No stores available. Please add a store first.');
                        }
                        // Initialize _selectedStore if it's null and there are stores
                        if (_selectedStore == null) {
                          _selectedStore = storeProvider.stores.first;
                        }
                        return DropdownButtonFormField<Store>(
                          value: _selectedStore,
                          decoration: const InputDecoration(labelText: 'Select Store'),
                          items: storeProvider.stores.map((store) {
                            return DropdownMenuItem<Store>(
                              value: store,
                              child: Text(store.name),
                            );
                          }).toList(),
                          onChanged: (Store? newValue) {
                            setState(() {
                              _selectedStore = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a store.';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    TextFormField(
                      controller: _roleController,
                      decoration: const InputDecoration(labelText: 'Role'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a role.';
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
                child: Text(_editingAttender == null ? 'Add' : 'Update'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attender Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAttenderDialog,
          ),
        ],
      ),
      body: Consumer<AttenderProvider>(
        builder: (context, attenderProvider, child) {
          if (attenderProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (attenderProvider.errorMessage != null) {
            return Center(
              child: Text('Error: ${attenderProvider.errorMessage}'),
            );
          }
          if (attenderProvider.attenders.isEmpty) {
            return const Center(
              child: Text('No attenders added yet. Click + to add one.'),
            );
          }
          return ListView.builder(
            itemCount: attenderProvider.attenders.length,
            itemBuilder: (ctx, i) {
              final attender = attenderProvider.attenders[i];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(attender.name),
                  subtitle: Text(attender.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editAttender(attender),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteAttender(attender.id),
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
