import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../models/cart_line.dart';
import '../providers/cart_provider.dart';
import '../services/cart_lead_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state.dart';
import 'checkout_screen.dart';
import 'home_screen.dart' show formatKes;

/// The cart list -- rewritten against the real API's variant-keyed cart.
///
/// Everything that used to live here (discount %, bargain amount, customer
/// type, the payment-method picker, the direct Paystack call with a secret
/// key compiled into the app) is gone: the backend prices every line from
/// its variant id at checkout, so there is nothing left for this screen to
/// override. Checking out is now a separate screen (CheckoutScreen), the
/// same "cart vs checkout are different steps" structure the web storefront
/// uses -- a distinct step exists so a shopper cannot change their mind by
/// accident mid-payment.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (!cart.ready) {
      return Scaffold(appBar: AppBar(title: const Text('Your Cart')), body: const Center(child: CircularProgressIndicator()));
    }

    if (cart.lines.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Cart')),
        body: EmptyState(
          glyph: EmptyStateGlyph.cart,
          title: 'Your cart is empty',
          message: 'Add products you like and they\'ll show up here.',
          actionLabel: 'Start shopping',
          onAction: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: cart.lines.length,
              separatorBuilder: (context, index) => const Divider(height: AppSpacing.hairline),
              itemBuilder: (context, index) {
                final line = cart.lines[index];
                return Dismissible(
                  key: ValueKey(line.variantId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: AppColors.danger,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  confirmDismiss: (direction) => _confirmRemove(context, cart, line.variantId, line.name),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          color: AppColors.de050,
                          child: line.imageUrl != null
                              ? Image.network(line.imageUrl!, fit: BoxFit.cover)
                              : const Icon(Icons.broken_image_outlined, color: AppColors.muted),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(line.name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                              if (line.size.isNotEmpty)
                                Text(line.size, style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  _StepperButton(
                                    icon: Icons.remove,
                                    onPressed: () => _decreaseOrConfirmRemove(context, cart, line.variantId, line.quantity, line.name),
                                  ),
                                  SizedBox(
                                    width: 32,
                                    child: Text('${line.quantity}', textAlign: TextAlign.center),
                                  ),
                                  _StepperButton(
                                    icon: Icons.add,
                                    onPressed: () => cart.setQuantity(line.variantId, line.quantity + 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatKes(line.lineTotal),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.royal, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.line, width: AppSpacing.hairline)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      formatKes(cart.subtotal),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.royal),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
                    },
                    child: const Text('CHECKOUT'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => buyCartViaWhatsApp(context, cart.lines),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.go, side: const BorderSide(color: AppColors.go)),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('BUY VIA WHATSAPP'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _decreaseOrConfirmRemove(BuildContext context, CartProvider cart, String variantId, int quantity, String name) {
    if (quantity > 1) {
      cart.setQuantity(variantId, quantity - 1);
      return;
    }
    _confirmRemove(context, cart, variantId, name);
  }

  Future<bool> _confirmRemove(BuildContext context, CartProvider cart, String variantId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text('Remove $name from your cart?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('REMOVE')),
        ],
      ),
    );
    if (confirmed == true) cart.remove(variantId);
    return confirmed ?? false;
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: AppColors.line, width: AppSpacing.hairline)),
        child: Icon(icon, size: 16, color: AppColors.royal),
      ),
    );
  }
}

/// Composes every cart line into a single structured WhatsApp message and
/// records the lead via [CartLeadService.recordWhatsAppOrder] -- shared by
/// the cart screen's own button and checkout's offline-payment notice, so
/// both routes produce the exact same message and lead record.
Future<void> buyCartViaWhatsApp(BuildContext context, List<CartLine> lines) async {
  if (lines.isEmpty) return;

  final buffer = StringBuffer('Hello, I would like to order the following:\n');
  for (final line in lines) {
    buffer.write('- ${line.name}');
    if (line.size.isNotEmpty) buffer.write(' (${line.size})');
    buffer.writeln(' x${line.quantity} - ${formatKes(line.lineTotal)}');
  }
  final total = lines.fold<num>(0, (sum, line) => sum + line.lineTotal);
  buffer.writeln('Total: ${formatKes(total)}');

  final whatsappUrl = 'https://wa.me/${ApiConfig.defaultWhatsAppNumber}?text=${Uri.encodeComponent(buffer.toString())}';

  // Fire-and-forget lead record -- must never block or fail the actual
  // WhatsApp launch below. Contact fields are left out here (name/phone/
  // email are all optional on the backend as long as at least one is
  // eventually provided elsewhere); a failure to record is swallowed since
  // a shopper's WhatsApp tap must work regardless of whether this succeeds.
  unawaited(context.read<CartLeadService>().recordWhatsAppOrder(lines: lines).catchError((_) {}));

  if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
    await launchUrl(Uri.parse(whatsappUrl));
  } else if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not launch WhatsApp. Please ensure it is installed.'), backgroundColor: AppColors.danger),
    );
  }
}
