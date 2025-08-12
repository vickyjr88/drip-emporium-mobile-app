import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DataRepository {
  static const String _lastFetchTimestampKey = 'last_fetch_timestamp';
  static const String _productsTableName = 'products';
  static const int _cacheDurationHours = 24;

  late Database _database;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'drip_emporium.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE $_productsTableName(id TEXT PRIMARY KEY, name TEXT, price REAL, imageUrl TEXT, description TEXT, link TEXT)',
        );
      },
      version: 2, // Increment version if you want to trigger onUpgrade
    );
  }

  Future<Map<String, dynamic>?> getUserDetails(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      print('Error fetching user details: $e');
      throw Exception('Failed to fetch user details: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? lastFetchTimestamp = prefs.getInt(_lastFetchTimestampKey);

    // Check cache
    if (lastFetchTimestamp != null &&
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastFetchTimestamp)).inHours < _cacheDurationHours) {
      final List<Map<String, dynamic>> cachedProducts = await _database.query(_productsTableName);
      if (cachedProducts.isNotEmpty) {
        print('Returning products from cache.');
        return cachedProducts;
      }
    }

    // Try Google Sheet API
    try {
      print('Attempting to fetch products from Google Sheet API...');
      final response = await http.get(Uri.parse('https://shengmtaa.com/api/private/facebook_catalog'));
      if (response.statusCode == 200) {
        print('API Response Body: ${response.body}'); // Log the response body
        final List<dynamic> data = json.decode(response.body);
        final List<Map<String, dynamic>> products = data.map((item) => {
          'id': item['id'],
          'name': item['title'],
          'price': double.parse(item['price'].toString().replaceAll(' KES', '').replaceAll(',', '')), // Parse price as double, remove commas
          'imageUrl': item['image_link'],
          'description': item['description'],
          'link': item['link'], // New: Capture share link
        }).toList();

        // Cache data
        await _database.delete(_productsTableName); // Clear old data
        for (var product in products) {
          await _database.insert(_productsTableName, product, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await prefs.setInt(_lastFetchTimestampKey, DateTime.now().millisecondsSinceEpoch);
        print('Successfully fetched and cached products from Google Sheet API.');
        return products;
      } else {
        print('Failed to fetch from Google Sheet API: ${response.statusCode}');
        throw Exception('Failed to load products. Server responded with status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching from Google Sheet API: $e');
      throw Exception('Network error: Could not connect to the product server.');
    }

    return []; // This line should ideally not be reached if exceptions are thrown
  }
}
