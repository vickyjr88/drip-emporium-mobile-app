import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:drip_emporium/providers/favorites_provider.dart';
import 'package:drip_emporium/providers/products_provider.dart'; // To get product details

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure favorites are fetched when screen is opened
    Provider.of<FavoritesProvider>(context, listen: false).fetchFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
      ),
      body: Consumer2<FavoritesProvider, ProductsProvider>(
        builder: (context, favoritesProvider, productsProvider, child) {
          if (productsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (favoritesProvider.favoriteProductIds.isEmpty) {
            return const Center(child: Text('No favorite products yet.'));
          }

          // Filter products to show only favorites
          final favoriteProducts = productsProvider.products.where((product) {
            return favoritesProvider.isFavorite(product['id']);
          }).toList();

          if (favoriteProducts.isEmpty) {
            return const Center(child: Text('No favorite products found in your catalog.'));
          }

          return ListView.builder(
            itemCount: favoriteProducts.length,
            itemBuilder: (context, index) {
              final product = favoriteProducts[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: SizedBox(
                    width: 60.0,
                    height: 60.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: CachedNetworkImage(
                        imageUrl: product['imageUrl'],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                  ),
                  title: Text(product['name']),
                  subtitle: Text('KES ${product['price'].toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      favoritesProvider.removeFavorite(product['id']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product['name']} removed from favorites.'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
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
