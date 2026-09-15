import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_auth_provider.dart';
import '../services/api_client.dart';
import '../services/customer_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'favorites_screen.dart';
import 'login_screen.dart';
import 'orders_screen.dart';
import 'settings_screen.dart';

/// Rewritten against the real backend's customer profile
/// (GET/PATCH /customer-portal/me). The old version's admin/attendant
/// branches (_isSuperAdmin, _isAttender, the Firestore superAdmins/attenders
/// lookups) are gone -- those belong to the staff/admin screens being
/// removed from this shopper-facing app entirely, not to a customer's own
/// profile page.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final customer = context.read<CustomerAuthProvider>().customer;
    if (customer != null) {
      _firstNameController.text = customer.firstName;
      _lastNameController.text = customer.lastName;
      _phoneController.text = customer.phone;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final api = context.read<CustomerApi>();
      final authProvider = context.read<CustomerAuthProvider>();
      await api.updateMe(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      await authProvider.refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved successfully!')));
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message), backgroundColor: AppColors.danger));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save profile. Check your connection and try again.'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can sign back in any time.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('LOG OUT')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<CustomerAuthProvider>().logout();
      if (mounted) Navigator.of(context).pop();
    }
  }

  String _initials(String firstName, String lastName) {
    final a = firstName.isNotEmpty ? firstName[0] : '';
    final b = lastName.isNotEmpty ? lastName[0] : '';
    final initials = (a + b).toUpperCase();
    return initials.isEmpty ? '?' : initials;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<CustomerAuthProvider>();
    final customer = auth.customer;

    if (!auth.isSignedIn || customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
            child: const Text('SIGN IN'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.royal,
                child: Text(
                  _initials(customer.firstName, customer.lastName),
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${customer.firstName} ${customer.lastName}'.trim(), style: Theme.of(context).textTheme.titleMedium),
                    Text(customer.email, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            decoration: BoxDecoration(border: Border.all(color: AppColors.line, width: AppSpacing.hairline)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text('Your Orders'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersScreen())),
                ),
                const Divider(height: AppSpacing.hairline),
                ListTile(
                  leading: const Icon(Icons.favorite_border),
                  title: const Text('Favorites'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesScreen())),
                ),
                const Divider(height: AppSpacing.hairline),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EDIT DETAILS', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 11 * 0.1)),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  initialValue: customer.email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  readOnly: true,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(children: [
                  Expanded(child: TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'First name'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                  )),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last name'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                  )),
                ]),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter your phone number' : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('SAVE PROFILE'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger, width: AppSpacing.hairline),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('LOG OUT'),
            ),
          ),
        ],
      ),
    );
  }
}
