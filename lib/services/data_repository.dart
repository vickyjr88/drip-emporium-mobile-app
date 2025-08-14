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
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE $_productsTableName ADD COLUMN link TEXT');
        }
      },
      version: 3, // Increment version to trigger onUpgrade
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

  Future<void> createOrUpdateUser({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
    String? phoneNumber,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final userDoc = await userRef.get();
      
      final userData = {
        'email': email,
        'displayName': displayName ?? '',
        'photoURL': photoURL ?? '',
        'phoneNumber': phoneNumber ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!userDoc.exists) {
        // Create new user with additional fields
        userData['createdAt'] = FieldValue.serverTimestamp();
        userData['address'] = '';
        userData['city'] = '';
        userData['postalCode'] = '';
        
        await userRef.set(userData);
        print('Created new user document for UID: $uid');
      } else {
        // Update existing user
        await userRef.update(userData);
        print('Updated existing user document for UID: $uid');
      }
    } catch (e) {
      print('Error creating/updating user: $e');
      throw Exception('Failed to create/update user: $e');
    }
  }

  Future<Map<String, dynamic>> fetchAllOrders({int limit = 10, DocumentSnapshot? startAfter}) async {
    try {
      Query query = _firestore.collection('orders').orderBy('timestamp', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.limit(limit).get();

      final orders = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['orderId'] = doc.id; // Add the document ID as 'orderId'
        return data;
      }).toList();

      final lastDocument = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
      final hasMore = querySnapshot.docs.length == limit;

      return {
        'orders': orders,
        'lastDocument': lastDocument,
        'hasMore': hasMore,
      };
    } catch (e) {
      print('Error fetching all orders: $e');
      throw Exception('Failed to fetch all orders: $e');
    }
  }

  Future<void> updateOrderStatusAdmin(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({'status': status});
    } catch (e) {
      print('Error updating order status for admin: $e');
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserOrders(String uid, {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['orderId'] = doc.id; // Add the document ID as 'orderId'
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching user orders: $e');
      throw Exception('Failed to fetch user orders: $e');
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
