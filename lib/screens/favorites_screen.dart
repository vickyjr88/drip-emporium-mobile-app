import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/favorite_product.dart';
import '../providers/customer_auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../services/shop_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_box.dart';
import 'home_screen.dart' show formatKes;
import 'login_screen.dart';
import 'product_details_screen.dart';

/// Rewritten against the real backend's favorites -- reads its own list
/// from FavoritesProvider directly, rather than filtering
/// ProductsProvider.products (the old approach), which silently dropped any
/// favorite that happened to be filtered out by the currently-selected
/// category or search query. That was the exact same root-cause bug as the
/// home feed's stores filter, showing up a second time.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().refresh();
    });
  }

  Future<void> _open(FavoriteProduct item) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final product = await context.read<ShopRepository>().fetchProduct(item.slug);
      if (!mounted) return;
      if (product == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This product is no longer available.'), backgroundColor: AppColors.danger),
        );
        return;
      }
      Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailsScreen(product: product)));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites')),
      body: Consumer2<CustomerAuthProvider, FavoritesProvider>(
        builder: (context, auth, favorites, child) {
          if (!auth.isSignedIn) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sign in to save and view your favorite products.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                      child: const Text('SIGN IN'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (favorites.isLoading && favorites.items.isEmpty) {
            return GridView.builder(
              padding: const EdgeInsets.all(1),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
                childAspectRatio: 0.72,
              ),
              itemCount: 4,
              itemBuilder: (context, index) => const SkeletonProductTile(),
            );
          }
          if (favorites.items.isEmpty) {
            return const EmptyState(
              glyph: EmptyStateGlyph.heart,
              title: 'No favorites yet',
              message: 'Tap the heart on a product to save it here.',
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(1),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
              childAspectRatio: 0.72,
            ),
            itemCount: favorites.items.length,
            itemBuilder: (context, index) {
              final item = favorites.items[index];
              // Material+InkWell, not a bare GestureDetector -- otherwise the
              // nested remove-favorite button's tap can also be won by this
              // outer tap-to-open handler, making it unreachable.
              return Material(
                color: AppColors.surface,
                child: InkWell(
                  onTap: () => _open(item),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            item.imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: item.imageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const SkeletonBox(),
                                    errorWidget: (context, url, error) => Container(
                                      color: AppColors.de050,
                                      child: const Icon(Icons.broken_image_outlined, color: AppColors.muted),
                                    ),
                                  )
                                : Container(color: AppColors.de050),
                            Positioned(
                              right: AppSpacing.xs,
                              top: AppSpacing.xs,
                              child: Material(
                                color: Colors.white.withValues(alpha: 0.9),
                                child: InkWell(
                                  onTap: () => context.read<FavoritesProvider>().removeFavorite(item.productId),
                                  child: const SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: Icon(Icons.favorite, size: 18, color: AppColors.danger),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.xs),
                        child: Text(
                          item.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.priceFrom != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
                          child: Text(
                            formatKes(item.priceFrom!),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.royal, fontWeight: FontWeight.w700),
                          ),
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
