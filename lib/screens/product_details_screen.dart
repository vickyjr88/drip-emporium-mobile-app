import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../models/cart_line.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../services/cart_lead_service.dart';
import '../services/shop_repository.dart';
import 'dart:async';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/cart_icon_button.dart';
import '../widgets/favorite_toggle.dart';
import '../widgets/section_header.dart';
import '../widgets/share_product.dart';
import 'home_screen.dart' show formatKes;

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String? _selectedVariantId;
  // The Product passed in usually comes straight from the grid/search list
  // (GET /shop/products), which never includes `related` -- only the
  // single-product endpoint (GET /shop/products/:slug) does. Navigation
  // stays instant (no spinner before the page opens) by using
  // widget.product as-is, then fetching the full detail in the background
  // to pick up `related` once it arrives.
  List<Product> _related = [];

  @override
  void initState() {
    super.initState();
    _selectedVariantId = _defaultVariantId();
    _related = widget.product.related;
    if (_related.isEmpty) _loadRelated();
  }

  Future<void> _loadRelated() async {
    final full = await context.read<ShopRepository>().fetchProduct(widget.product.slug);
    if (mounted && full != null && full.related.isNotEmpty) {
      setState(() => _related = full.related);
    }
  }

  /// Default selection precedence, matching the web storefront exactly:
  /// first in-stock-and-discounted, then first in-stock, then first
  /// orderable, then simply the first variant if nothing else qualifies.
  String? _defaultVariantId() {
    final variants = widget.product.variants;
    if (variants.isEmpty) return null;

    for (final variant in variants) {
      if (variant.inStock && variant.wasPriceKes != null) return variant.id;
    }
    for (final variant in variants) {
      if (variant.inStock) return variant.id;
    }
    for (final variant in variants) {
      if (variant.canOrder) return variant.id;
    }
    return variants.first.id;
  }

  ProductVariant? get _selectedVariant {
    final id = _selectedVariantId;
    if (id == null) return null;
    for (final variant in widget.product.variants) {
      if (variant.id == id) return variant;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final chosen = _selectedVariant;
    final shareLink = '${ApiConfig.storefrontOrigin}/shop/${product.slug}';
    final shareText = '${product.name} — ${product.priceLabel(formatKes)} $shareLink';

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => shareProduct(context, shareText),
            ),
          ),
          const CartIconButton(),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImageCarousel(imageUrls: product.imageUrls),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.sm),
                  _PriceRow(product: product, chosen: chosen),
                  const SizedBox(height: AppSpacing.lg),
                  if (product.hasSizes) ...[
                    Text('SELECT SIZE', style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 11 * 0.1,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: AppSpacing.sm),
                    _SizeSelector(
                      product: product,
                      selectedId: _selectedVariantId,
                      onSelect: (id) => setState(() => _selectedVariantId = id),
                    ),
                    if (chosen != null && !chosen.inStock && chosen.canOrder) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Order in -- ships once restocked from the supplier.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (product.description != null && product.description!.isNotEmpty)
                    _ExpandableDescription(text: product.description!),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _buyViaWhatsApp(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.go,
                        foregroundColor: Colors.white,
                      ),
                      icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                      label: const Text('BUY VIA WHATSAPP'),
                    ),
                  ),
                ],
              ),
            ),
            if (_related.isNotEmpty) _RelatedProducts(products: _related),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.line, width: AppSpacing.hairline)),
        ),
        child: Row(
          children: [
            Consumer<FavoritesProvider>(
              builder: (context, favoritesProvider, child) {
                final isFavorite = favoritesProvider.isFavorite(product.id);
                return Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(border: Border.all(color: AppColors.line, width: AppSpacing.hairline)),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => toggleFavorite(context, product.id),
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? AppColors.danger : AppColors.royal,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton(
                onPressed: chosen == null ? null : () => _addToCart(context, chosen),
                child: Text(chosen == null ? 'SELECT A SIZE' : 'ADD TO CART'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(BuildContext context, ProductVariant variant) {
    context.read<CartProvider>().add(CartLine(
          variantId: variant.id,
          productSlug: widget.product.slug,
          name: widget.product.name,
          size: variant.displayLabel,
          sku: variant.sku,
          priceKes: variant.priceKes,
          imageUrl: widget.product.primaryImageUrl,
          quantity: 1,
        ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.product.name} added to cart!'), duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _buyViaWhatsApp(BuildContext context) async {
    final product = widget.product;
    final chosen = _selectedVariant;
    final shareLink = '${ApiConfig.storefrontOrigin}/shop/${product.slug}';

    // Same real number used everywhere else in the app now -- this screen
    // previously had a different, placeholder number hardcoded
    // (+254712345678), so its WhatsApp button messaged nobody real.
    final buffer = StringBuffer('Hello, I would like to order the following product:\n');
    buffer.writeln('Product: ${product.name}');
    if (chosen != null) {
      if (chosen.size != null) buffer.writeln('Size: ${chosen.displayLabel}');
      buffer.writeln('SKU: ${chosen.sku}');
      buffer.writeln('Price: ${formatKes(chosen.priceKes)}');
      if (!chosen.inStock) buffer.writeln('(Currently ordered in from supplier)');
    }
    buffer.writeln('Link: $shareLink');

    final whatsappUrl = 'https://wa.me/${ApiConfig.defaultWhatsAppNumber}?text=${Uri.encodeComponent(buffer.toString())}';

    // Fire-and-forget analytics -- must never block or fail the actual
    // WhatsApp launch below. Any failure (offline, a dropped request) is
    // swallowed here on purpose: a shopper's WhatsApp tap must work
    // regardless of whether this succeeds.
    unawaited(context.read<CartLeadService>().recordWhatsAppClick(source: 'product-page').catchError((_) {}));

    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp. Please ensure it is installed.'), backgroundColor: AppColors.danger),
      );
    }
  }
}

class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({required this.imageUrls});

  final List<String> imageUrls;

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return Container(
        height: 340,
        color: AppColors.de050,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined, size: 64, color: AppColors.de300),
      );
    }

    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 340.0,
            enlargeCenterPage: false,
            autoPlay: false,
            viewportFraction: 1.0,
            onPageChanged: (index, reason) => setState(() => _index = index),
          ),
          items: widget.imageUrls.map((url) {
            return Builder(
              builder: (context) => Container(
                width: MediaQuery.of(context).size.width,
                color: AppColors.de050,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image_outlined, size: 64, color: AppColors.de300)),
                ),
              ),
            );
          }).toList(),
        ),
        if (widget.imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.imageUrls.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  color: _index == entry.key ? AppColors.royal : AppColors.de200,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.product, required this.chosen});

  final Product product;
  final ProductVariant? chosen;

  @override
  Widget build(BuildContext context) {
    final priceText = chosen != null ? formatKes(chosen!.priceKes) : product.priceLabel(formatKes);
    final wasPrice = chosen?.wasPriceKes;
    final retailPrice = chosen?.retailPriceKes;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      children: [
        Text(
          priceText,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.royal),
        ),
        if (wasPrice != null)
          Text(
            formatKes(wasPrice),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: AppColors.muted,
                ),
          ),
        // Only ever present for a logged-in reseller/wholesale customer --
        // a retail shopper or guest never sees this.
        if (retailPrice != null)
          Text(
            'Retail ${formatKes(retailPrice)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _SizeSelector extends StatelessWidget {
  const _SizeSelector({required this.product, required this.selectedId, required this.onSelect});

  final Product product;
  final String? selectedId;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: product.variants.map((variant) {
        final selected = variant.id == selectedId;
        // Out-of-stock sizes are shown, not hidden -- they're still
        // orderable from the supplier. Disabled only when genuinely
        // un-orderable.
        final orderIn = !variant.inStock && variant.canOrder;
        return ChoiceChip(
          label: Text(variant.displayLabel.replaceFirst('EUR ', '')),
          selected: selected,
          onSelected: variant.canOrder ? (_) => onSelect(variant.id) : null,
          backgroundColor: orderIn ? AppColors.surface : null,
          side: orderIn ? const BorderSide(color: AppColors.de300, width: AppSpacing.hairline) : null,
        );
      }).toList(),
    );
  }
}

class _ExpandableDescription extends StatefulWidget {
  const _ExpandableDescription({required this.text});

  final String text;

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: _expanded ? null : 4,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              _expanded ? 'SHOW LESS' : 'READ MORE',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.royal,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "You might also like" -- a horizontal rail of same-category alternatives,
/// embedded directly on the product-details response (`related`) so a
/// sold-out size or a browse that doesn't convert isn't a dead end.
class _RelatedProducts extends StatelessWidget {
  const _RelatedProducts({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'You might also like'),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) => _RelatedProductCard(product: products[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedProductCard extends StatelessWidget {
  const _RelatedProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.primaryImageUrl;
    return SizedBox(
      width: 140,
      child: Material(
        color: AppColors.surface,
        child: InkWell(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ProductDetailsScreen(product: product)),
            );
          },
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: AppColors.line, width: AppSpacing.hairline)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 5,
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: AppColors.de050),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.de050,
                            child: const Icon(Icons.broken_image_outlined, color: AppColors.muted),
                          ),
                        )
                      : Container(color: AppColors.de050),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        product.priceLabel(formatKes),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.royal, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
