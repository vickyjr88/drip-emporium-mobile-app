import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../screens/cart_screen.dart';

/// Cart icon with a live item-count badge. Replaces the hand-rolled
/// Stack+Positioned+red-Container badges duplicated in the home and
/// product-details screens.
class CartIconButton extends StatelessWidget {
  const CartIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return IconButton(
          icon: Badge.count(
            count: cart.count,
            isLabelVisible: cart.count > 0,
            child: const Icon(Icons.shopping_cart_outlined),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
        );
      },
    );
  }
}
