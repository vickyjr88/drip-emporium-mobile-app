import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_line.dart';
import '../providers/cart_provider.dart';
import '../providers/customer_auth_provider.dart';
import '../services/api_client.dart';
import '../services/cart_lead_service.dart';
import '../services/checkout_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/section_header.dart';
import 'cart_screen.dart' show buyCartViaWhatsApp;
import 'home_screen.dart' show formatKes;
import 'payment_webview_screen.dart';

/// Guest checkout is first-class: the backend allows it, and the old
/// Firebase-login-required gate (a null-check assertion the app never
/// actually guarded against) is a defect, not a design choice a real
/// storefront would make -- requiring an account is one of the surest ways
/// to lose a sale.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _createAccount = false;
  bool _submitting = false;
  bool? _onlineAvailable;

  Timer? _abandonedCartDebounce;

  @override
  void initState() {
    super.initState();
    final auth = context.read<CustomerAuthProvider>();
    // Signed-in customers get their known details prefilled -- only filling
    // blanks, so nothing here overwrites something the shopper already typed.
    if (auth.customer != null) {
      _firstNameController.text = auth.customer!.firstName;
      _lastNameController.text = auth.customer!.lastName;
      _emailController.text = auth.customer!.email;
      _phoneController.text = auth.customer!.phone;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConfig());

    // Same debounced abandoned-cart sync the web storefront runs: a cart
    // left sitting here with a way to reach the shopper (email or phone)
    // is worth a follow-up lead, so re-sync it (2s after the shopper stops
    // typing, matching web) any time that contact info changes. The
    // backend dedupes by contact against any existing NEW ABANDONED_CART
    // lead, so this is safe to call repeatedly.
    _emailController.addListener(_scheduleAbandonedCartSync);
    _phoneController.addListener(_scheduleAbandonedCartSync);
    _firstNameController.addListener(_scheduleAbandonedCartSync);
    _lastNameController.addListener(_scheduleAbandonedCartSync);
    _addressController.addListener(_scheduleAbandonedCartSync);

    // A signed-in customer already has contact details prefilled above --
    // that alone should still start the same countdown, not just an edit
    // the shopper types afterwards.
    if (auth.customer != null) _scheduleAbandonedCartSync();
  }

  Future<void> _loadConfig() async {
    final online = await context.read<CheckoutRepository>().fetchConfig();
    if (mounted) setState(() => _onlineAvailable = online);
  }

  void _scheduleAbandonedCartSync() {
    _abandonedCartDebounce?.cancel();
    _abandonedCartDebounce = Timer(const Duration(seconds: 2), _syncAbandonedCart);
  }

  void _syncAbandonedCart() {
    if (!mounted || _submitting) return;
    final cart = context.read<CartProvider>();
    if (cart.lines.isEmpty) return;

    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    if (phone.isEmpty && email.isEmpty) return;

    final name = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
    unawaited(context.read<CartLeadService>().syncAbandoned(
          lines: cart.lines,
          customerName: name.isEmpty ? null : name,
          customerPhone: phone.isEmpty ? null : phone,
          customerEmail: email.isEmpty ? null : email,
          shippingAddress: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        ).catchError((_) {
          // Best-effort: a shopper's checkout must never depend on this.
        }));
  }

  @override
  void dispose() {
    _abandonedCartDebounce?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(List<CartLine> lines) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final repository = context.read<CheckoutRepository>();
      final session = await repository.startCheckout(
        lines: lines.map((line) => CheckoutLine(variantId: line.variantId, quantity: line.quantity)).toList(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        shippingAddress: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        password: _createAccount ? _passwordController.text : null,
      );

      if (!mounted) return;

      // Do NOT clear the cart yet -- the shopper may back out of the
      // payment sheet with nothing charged. Only a confirmed `paid` result
      // (see below) clears it.
      final reference = await Navigator.of(context).push<String?>(
        MaterialPageRoute(builder: (_) => PaymentWebViewScreen(authorizationUrl: session.authorizationUrl)),
      );

      if (!mounted) return;
      if (reference == null) {
        // Backed out of the WebView without paying -- the order sits
        // unpaid server-side; leaving the cart alone lets them try again.
        setState(() => _submitting = false);
        return;
      }

      final result = await repository.verify(reference);
      if (!mounted) return;

      if (result.paid) {
        context.read<CartProvider>().clear();
        _showResultAndClose(orderNumber: result.orderNumber, paid: true);
      } else {
        setState(() => _submitting = false);
        _showResultAndClose(orderNumber: result.orderNumber, paid: false);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message), backgroundColor: AppColors.danger));
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Check your connection and try again.'), backgroundColor: AppColors.danger),
      );
    }
  }

  void _showResultAndClose({required String orderNumber, required bool paid}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(paid ? 'Order confirmed' : 'Payment not completed'),
        content: Text(paid
            ? 'Order $orderNumber is paid. Thank you!'
            : 'Order $orderNumber was not paid. You can try again from your cart.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (_onlineAvailable == false)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  border: Border.all(color: AppColors.warning, width: AppSpacing.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Online payment is temporarily unavailable.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.warning, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => buyCartViaWhatsApp(context, cart.lines),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.go, side: const BorderSide(color: AppColors.go)),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('MESSAGE US ON WHATSAPP'),
                      ),
                    ),
                  ],
                ),
              ),
            _OrderSummary(lines: cart.lines),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Contact'),
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
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone (e.g. +254...)'),
              keyboardType: TextInputType.phone,
              validator: (value) => (value == null || value.trim().length < 9) ? 'Enter a valid phone number' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Delivery'),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Delivery address (optional -- leave blank to collect at the shop)'),
            ),
            if (context.watch<CustomerAuthProvider>().customer == null) ...[
              const SizedBox(height: AppSpacing.md),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _createAccount,
                title: const Text('Create an account with these details'),
                onChanged: (value) => setState(() => _createAccount = value ?? false),
              ),
              if (_createAccount)
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (!_createAccount) return null;
                    return (value == null || value.length < 8) ? 'At least 8 characters' : null;
                  },
                ),
            ],
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.line, width: AppSpacing.hairline)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: Theme.of(context).textTheme.titleMedium),
                Text(formatKes(cart.subtotal), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.royal)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_submitting || _onlineAvailable == false || cart.lines.isEmpty)
                    ? null
                    : () => _submit(cart.lines),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('PAY NOW'),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Secured by Paystack',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.lines});

  final List<CartLine> lines;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line, width: AppSpacing.hairline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${lines.fold<int>(0, (sum, line) => sum + line.quantity)} item(s)',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: lines.length,
              separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final line = lines[index];
                return Container(
                  width: 56,
                  height: 56,
                  color: AppColors.de050,
                  child: line.imageUrl != null
                      ? Image.network(line.imageUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.broken_image_outlined, size: 18, color: AppColors.muted),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
