import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import 'package:drip_emporium/providers/cart_provider.dart';
import 'package:cached_network_image/cached_network_image.dart'; // New import
import 'package:drip_emporium/screens/cart_screen.dart'; // New import

import 'package:drip_emporium/services/payment_service.dart'; // New import

class ProductDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  final PaymentService paymentService; // New field

  const ProductDetailsScreen({super.key, required this.product, required this.paymentService}); // Updated constructor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartScreen(paymentService: paymentService)),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Carousel
            CarouselSlider(
              options: CarouselOptions(
                height: 300.0,
                enlargeCenterPage: true,
                autoPlay: false, // Set to true if you want auto-play
                aspectRatio: 16 / 9,
                viewportFraction: 0.8,
              ),
              items: [product['imageUrl']].map((i) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                      ),
                      child: SizedBox( // New SizedBox to enforce square
                        width: 200.0, // Example width
                        height: 200.0, // Example height
                        child: CachedNetworkImage(
                          imageUrl: i,
                          fit: BoxFit.cover, // Ensures image covers the square, cropping if necessary
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, size: 100)),
                        ),
                      ),
                    ); // Closing parenthesis for Container
                  },
                );
              }).toList(),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'KES ${product['price'].toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary, // Changed to primary (blue)
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    product['description'],
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
            ),
            // Add to Cart Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Provider.of<CartProvider>(context, listen: false).addItem(
                      product['id'],
                      product['name'],
                      product['price'],
                      product['imageUrl'],
                      product['link'],
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product['name']} added to cart!'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary, // Changed to primary (blue)
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                  ),
                  child: const Text(
                    'Add to Cart',
                    style: TextStyle(fontSize: 18.0, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
