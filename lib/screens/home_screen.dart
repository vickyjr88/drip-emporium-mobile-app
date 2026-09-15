import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../models/cart_line.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/products_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/cart_icon_button.dart';
import '../widgets/empty_state.dart';
import '../widgets/favorite_toggle.dart';
import '../widgets/share_product.dart';
import '../widgets/skeleton_box.dart';
import 'product_details_screen.dart';
import 'settings_screen.dart';

/// "KSh 3,500" -- shared with the product detail screen so both agree on
/// formatting. No `intl` NumberFormat here on purpose: thousands separators
/// via `intl` need a locale data init this app doesn't otherwise need, and a
/// manual grouping is simpler for a single currency that's always whole
/// shillings.
String formatKes(num amount) {
  final rounded = amount.round();
  final digits = rounded.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return 'KSh $buffer';
}

/// Extracted out of main.dart, where it did not belong -- also where the
/// store-chip filter (the root cause of "no products found") lived. Rewired
/// against the real API's ProductsProvider: no store concept survives here
/// at all, since the backend has no per-store product filtering to offer.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Loaded here, not in the provider's constructor -- a provider firing
    // network calls before any widget exists is untestable and, worse,
    // fires once per provider instance regardless of whether a screen ever
    // shows its results.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductsProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<ProductsProvider>().setSearch(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drip Emporium'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const CartIconButton(),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ProductsProvider>().refresh(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, color: AppColors.muted),
                          onPressed: () => _searchController.clear(),
                        ),
                ),
              ),
            ),
            // Category chips, replacing the old store-chip row entirely --
            // the real API has no per-store product concept to filter on.
            Consumer<ProductsProvider>(
              builder: (context, products, child) {
                if (products.categories.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: ChoiceChip(
                            label: const Text('All'),
                            selected: products.selectedCategory == null,
                            onSelected: (selected) {
                              if (selected) products.setCategory(null);
                            },
                          ),
                        ),
                        ...products.categories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.xs,
                            ),
                            child: ChoiceChip(
                              label: Text(category.name),
                              selected:
                                  products.selectedCategory == category.slug,
                              onSelected: (selected) {
                                if (selected) {
                                  products.setCategory(category.slug);
                                }
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Divider(height: AppSpacing.hairline),
            Expanded(
              child: Consumer<ProductsProvider>(
                builder: (context, products, child) {
                  // "Failed to load" and "no results for this filter" are
                  // deliberately distinct branches -- conflating them (as the
                  // old code did with one "No products found" message) is
                  // exactly how the original feed bug went unnoticed.
                  if (products.isLoading && products.products.isEmpty) {
                    return GridView.builder(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppSpacing.sm,
                            mainAxisSpacing: AppSpacing.sm,
                            childAspectRatio: 0.62,
                          ),
                      itemCount: 6,
                      itemBuilder: (context, index) =>
                          const SkeletonProductTile(),
                    );
                  }
                  if (products.error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              products.error!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ElevatedButton(
                              onPressed: () => products.refresh(),
                              child: const Text('TRY AGAIN'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (products.products.isEmpty) {
                    return const EmptyState(
                      glyph: EmptyStateGlyph.search,
                      title: 'No products found',
                      message: 'Try a different search term or category.',
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.sm,
                          mainAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 0.62,
                        ),
                    itemCount: products.products.length,
                    itemBuilder: (context, index) {
                      final tile = _ProductCard(
                        product: products.products[index],
                      );
                      // Staggered fade-in, capped so scrolling further down
                      // the grid never feels gated behind an animation.
                      final delay = Duration(milliseconds: 30 * (index % 8));
                      return tile.animate().fadeIn(
                        delay: delay,
                        duration: const Duration(milliseconds: 220),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.primaryImageUrl;
    final shareLink = '${ApiConfig.storefrontOrigin}/shop/${product.slug}';

    // Material+InkWell, not a bare GestureDetector -- a plain GestureDetector
    // ancestor could win the gesture arena over the share/favorite buttons
    // nested inside it, making them unreachable. InkWell's tap recognizer
    // correctly yields to a descendant Material tap target instead.
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line, width: AppSpacing.hairline),
      ),
      child: Material(
        color: AppColors.surface,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(product: product),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 5,
                      child: imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const SkeletonBox(),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.de050,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.muted,
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.de050,
                              alignment: Alignment.center,
                              child: Text(
                                product.name.isNotEmpty ? product.name[0] : '?',
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(color: AppColors.de300),
                              ),
                            ),
                    ),
                    if (product.onOffer)
                      Positioned(
                        left: 0,
                        top: AppSpacing.sm,
                        child: _Tag(
                          label: product.offerLabel ?? 'OFFER',
                          background: AppColors.go,
                        ),
                      ),
                    if (!product.anyInStock)
                      Positioned(
                        left: 0,
                        bottom: AppSpacing.sm,
                        child: _Tag(
                          label: 'ORDER IN',
                          background: AppColors.de900.withValues(alpha: 0.75),
                        ),
                      ),
                    Positioned(
                      right: AppSpacing.xs,
                      top: AppSpacing.xs,
                      child: Consumer<FavoritesProvider>(
                        builder: (context, favorites, child) {
                          final isFavorite = favorites.isFavorite(product.id);
                          return _CircleIconButton(
                            icon: isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isFavorite
                                ? AppColors.danger
                                : AppColors.ink,
                            onPressed: () =>
                                toggleFavorite(context, product.id),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.xs,
                ),
                child: Text(
                  product.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.priceLabel(formatKes),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.royal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Builder(
                      builder: (context) => IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.share_outlined,
                          size: 18,
                          color: AppColors.muted,
                        ),
                        onPressed: () => shareProduct(
                          context,
                          'Check out this product: ${product.name} - ${product.priceLabel(formatKes)} $shareLink',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: product.variants.isEmpty
                        ? null
                        : () => _addToCart(context),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.de050,
                      foregroundColor: AppColors.royal,
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                    ),
                    child: Text(
                      'ADD TO CART',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.royal,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 11 * 0.12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addToCart(BuildContext context) {
    // A card has no room for a size picker -- add the first orderable
    // variant directly, same shortcut the web storefront's card takes when
    // there is nothing meaningful to choose between (a single-variant
    // product) or, here, simply to keep the grid interaction fast. A
    // shopper who wants a specific size opens the product page.
    final variant = product.variants.firstWhere(
      (variant) => variant.canOrder,
      orElse: () => product.variants.first,
    );
    context.read<CartProvider>().add(
      CartLine(
        variantId: variant.id,
        productSlug: product.slug,
        name: product.name,
        size: variant.displayLabel,
        sku: variant.sku,
        priceKes: variant.priceKes,
        imageUrl: product.primaryImageUrl,
        quantity: 1,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.background});

  final String label;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      color: background,
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 9 * 0.08,
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Material+InkWell (not a bare GestureDetector) so the tap is properly
    // claimed and absorbed here instead of also reaching the card's own
    // GestureDetector.onTap underneath -- a bare GestureDetector let both
    // fire, so tapping the heart also navigated into product details.
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
