import 'package:drip_emporium/models/attender.dart';
import 'package:drip_emporium/models/store.dart';
import 'package:drip_emporium/providers/store_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AttendantFormDialog extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Attender? existingAttender; // Optional, for editing

  const AttendantFormDialog({
    super.key,
    required this.userData,
    this.existingAttender,
  });

  @override
  State<AttendantFormDialog> createState() => _AttendantFormDialogState();
}

class _AttendantFormDialogState extends State<AttendantFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileNumberController;
  String? _selectedRole;
  Store? _selectedStore;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.userData['displayName'] ?? '');
    _emailController =
        TextEditingController(text: widget.userData['email'] ?? '');
    _mobileNumberController =
        TextEditingController(text: widget.userData['mobileNumber'] ?? '');

    if (widget.existingAttender != null) {
      _nameController.text = widget.existingAttender!.name;
      _emailController.text = widget.existingAttender!.email;
      _mobileNumberController.text = widget.existingAttender!.mobileNumber;
      _selectedRole = widget.existingAttender!.role;
      // Find and set the existing store
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final storeProvider = Provider.of<StoreProvider>(context, listen: false);
        _selectedStore = storeProvider.stores.firstWhere(
          (store) => store.id == widget.existingAttender!.storeId,
          orElse: () => storeProvider.stores.first, // Fallback
        );
        setState(() {});
      });
    } else {
      _selectedRole = 'Attendant'; // Default role for new attendant
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingAttender == null
          ? 'Make Attendant'
          : 'Edit Attendant'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name.';
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
              TextFormField(
                controller: _mobileNumberController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number.';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: <String>['Attendant', 'Manager', 'Admin']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRole = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a role.';
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
                    return const Text('No stores available.');
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Dismiss dialog
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final attender = Attender(
                id: widget.userData['userId'] ?? widget.existingAttender?.id ?? '', // Use userId from userData or existingAttender
                name: _nameController.text,
                email: _emailController.text,
                storeId: _selectedStore!.id,
                role: _selectedRole!,
                mobileNumber: _mobileNumberController.text,
              );
              Navigator.of(context).pop(attender); // Return attender object
            }
          },
          child: Text(widget.existingAttender == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}
