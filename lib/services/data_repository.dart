import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/store.dart';
import '../models/attender.dart';
import '../models/customer.dart';
import '../models/order.dart';

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
          'CREATE TABLE $_productsTableName(id TEXT PRIMARY KEY, name TEXT, price REAL, imageUrl TEXT, description TEXT, link TEXT, availability TEXT, condition TEXT, brand TEXT, sale_price REAL, color TEXT, size TEXT, product_tags TEXT, categories TEXT, stores TEXT DEFAULT \'Drip Emporium\')',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE $_productsTableName ADD COLUMN link TEXT',
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE $_productsTableName ADD COLUMN availability TEXT',
          );
          await db.execute(
            'ALTER TABLE $_productsTableName ADD COLUMN condition TEXT',
          );
          await db.execute(
            'ALTER TABLE $_productsTableName ADD COLUMN brand TEXT',
          );
          await db.execute(
            'ALTER TABLE $_productsTableName ADD COLUMN sale_price REAL',
          );
          await db.execute(
            'ALTER TABLE $_productsTableName ADD COLUMN color TEXT',
          );
          await db.execute(
            'ALTER TABLE $_productsTableName ADD COLUMN size TEXT',
          );
          await db.execute(
            'ALTER TABLE $_productsTableName ADD COLUMN product_tags TEXT',
          );
          await db.execute(
            'ALTER TABLE $_productsTableName ADD COLUMN categories TEXT',
          );
          await db.execute(
            'ALTER TABLE $_productsTableName ADD COLUMN stores TEXT DEFAULT \'Drip Emporium\'',
          );
        }
      },
      version: 4, // Increment version to trigger onUpgrade
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
    CustomerType? customerType,
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

      if (customerType != null) {
        userData['customerType'] = customerType.toString().split('.').last;
      }

      if (!userDoc.exists) {
        // Create new user with additional fields
        userData['createdAt'] = FieldValue.serverTimestamp();
        userData['address'] = '';
        userData['city'] = '';
        userData['postalCode'] = '';
        userData['customerType'] =
            customerType?.toString().split('.').last ??
            CustomerType.client.toString().split('.').last;

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

  Future<void> updateCustomerType(String uid, CustomerType customerType) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'customerType': customerType.toString().split('.').last,
      });
    } catch (e) {
      print('Error updating customer type: $e');
      throw Exception('Failed to update customer type: $e');
    }
  }

  // Order Management
  Future<void> createOrder(Order order) async {
    try {
      await _firestore
          .collection('orders')
          .doc(order.id)
          .set(order.toFirestore());
    } catch (e) {
      print('Error creating order: $e');
      throw Exception('Failed to create order: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status.toString().split('.').last,
      });
    } catch (e) {
      print('Error updating order status: $e');
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<List<Order>> getOrdersByStore(String storeId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('orders')
              .where('storeId', isEqualTo: storeId)
              .get();
      return querySnapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting orders by store: $e');
      throw Exception('Failed to get orders by store: $e');
    }
  }

  Future<List<Order>> getOrdersByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? storeId,
  }) async {
    try {
      Query query = _firestore
          .collection('orders')
          .where('orderDate', isGreaterThanOrEqualTo: startDate)
          .where('orderDate', isLessThanOrEqualTo: endDate);

      if (storeId != null) {
        query = query.where('storeId', isEqualTo: storeId);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting orders by date range: $e');
      throw Exception('Failed to get orders by date range: $e');
    }
  }

  // Sales Statistics
  Future<Map<String, double>> getDailySalesStatistics(
    DateTime date, {
    String? storeId,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      List<Order> orders = await getOrdersByDateRange(
        startOfDay,
        endOfDay,
        storeId: storeId,
      );

      double totalSales = 0.0;
      for (var order in orders) {
        totalSales += order.finalPrice;
      }
      return {'totalSales': totalSales};
    } catch (e) {
      print('Error getting daily sales statistics: $e');
      throw Exception('Failed to get daily sales statistics: $e');
    }
  }

  Future<Map<String, double>> getWeeklySalesStatistics(
    DateTime date, {
    String? storeId,
  }) async {
    try {
      // Get the start of the week (Monday)
      DateTime startOfWeek = date.subtract(Duration(days: date.weekday - 1));
      startOfWeek = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );
      final endOfWeek = startOfWeek.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );

      List<Order> orders = await getOrdersByDateRange(
        startOfWeek,
        endOfWeek,
        storeId: storeId,
      );

      double totalSales = 0.0;
      for (var order in orders) {
        totalSales += order.finalPrice;
      }
      return {'totalSales': totalSales};
    } catch (e) {
      print('Error getting weekly sales statistics: $e');
      throw Exception('Failed to get weekly sales statistics: $e');
    }
  }

  // Store Management
  Future<void> addStore(Store store) async {
    try {
      await _firestore
          .collection('stores')
          .doc(store.id)
          .set(store.toFirestore());
    } catch (e) {
      print('Error adding store: $e');
      throw Exception('Failed to add store: $e');
    }
  }

  Future<List<Store>> getStores() async {
    try {
      final querySnapshot = await _firestore.collection('stores').get();
      return querySnapshot.docs.map((doc) => Store.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting stores: $e');
      throw Exception('Failed to get stores: $e');
    }
  }

  Future<void> updateStore(Store store) async {
    try {
      await _firestore
          .collection('stores')
          .doc(store.id)
          .update(store.toFirestore());
    } catch (e) {
      print('Error updating store: $e');
      throw Exception('Failed to update store: $e');
    }
  }

  Future<void> deleteStore(String storeId) async {
    try {
      await _firestore.collection('stores').doc(storeId).delete();
    } catch (e) {
      print('Error deleting store: $e');
      throw Exception('Failed to delete store: $e');
    }
  }

  // Attender Management
  Future<void> addAttender(Attender attender) async {
    try {
      await _firestore
          .collection('attenders')
          .doc(attender.id)
          .set(attender.toFirestore());
    } catch (e) {
      print('Error adding attender: $e');
      throw Exception('Failed to add attender: $e');
    }
  }

  Future<List<Attender>> getAttenders() async {
    try {
      final querySnapshot = await _firestore.collection('attenders').get();
      return querySnapshot.docs
          .map((doc) => Attender.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting attenders: $e');
      throw Exception('Failed to get attenders: $e');
    }
  }

  Future<void> updateAttender(Attender attender) async {
    try {
      await _firestore
          .collection('attenders')
          .doc(attender.id)
          .update(attender.toFirestore());
    } catch (e) {
      print('Error updating attender: $e');
      throw Exception('Failed to update attender: $e');
    }
  }

  Future<void> deleteAttender(String attenderId) async {
    try {
      await _firestore.collection('attenders').doc(attenderId).delete();
    } catch (e) {
      print('Error deleting attender: $e');
      throw Exception('Failed to delete attender: $e');
    }
  }

  Future<Attender?> getAttender(String uid) async {
    try {
      final doc = await _firestore.collection('attenders').doc(uid).get();
      if (doc.exists) {
        return Attender.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting attender: $e');
      throw Exception('Failed to get attender: $e');
    }
  }

  Future<List<Customer>> getCustomers() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      return querySnapshot.docs
          .map((doc) => Customer.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting customers: $e');
      throw Exception('Failed to get customers: $e');
    }
  }

  Future<Map<String, dynamic>> fetchAllOrders({
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('orders')
          .orderBy('timestamp', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.limit(limit).get();

      final orders =
          querySnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['orderId'] = doc.id; // Add the document ID as 'orderId'
            return data;
          }).toList();

      final lastDocument =
          querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
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

  Future<List<Map<String, dynamic>>> fetchUserOrders(
    String uid, {
    int limit = 20,
  }) async {
    try {
      final querySnapshot =
          await _firestore
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
        DateTime.now()
                .difference(
                  DateTime.fromMillisecondsSinceEpoch(lastFetchTimestamp),
                )
                .inHours <
            _cacheDurationHours) {
      final List<Map<String, dynamic>> cachedProducts = await _database.query(
        _productsTableName,
      );
      if (cachedProducts.isNotEmpty) {
        print('Returning products from cache.');
        return cachedProducts;
      }
    }

    // Try Google Sheet API
    try {
      final url = 'https://shengmtaa.com/api/private/v2/facebook_catalog';
      print(
        'Attempting to fetch products from Google Sheet API from URL: $url',
      );
      final response = await http.get(Uri.parse(url));
      print('API Response Status Code: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('API Response Body: ${response.body}'); // Log the response body
        final List<dynamic> data = json.decode(response.body);
        final List<Map<String, dynamic>> products =
            data
                .map(
                  (item) => {
                    'id': item['id'],
                    'name': item['title'],
                    'price': double.parse(
                      item['price']
                          .toString()
                          .replaceAll(' KES', '')
                          .replaceAll(',', ''),
                    ), // Parse price as double, remove commas
                    'imageUrl': item['image_link'],
                    'description': item['description'],
                    'link': item['link'], // New: Capture share link
                    'availability': item['availability'] ?? '',
                    'condition': item['condition'] ?? '',
                    'brand': item['brand'] ?? '',
                    'sale_price':
                        item['sale_price'] != null
                            ? double.parse(
                              item['sale_price']
                                  .toString()
                                  .replaceAll(' KES', '')
                                  .replaceAll(',', ''),
                            )
                            : null,
                    'color': item['color'] ?? '',
                    'size': item['size'] ?? '',
                    'product_tags': item['product_tags'] ?? '',
                    'categories': item['categories'] ?? '',
                    'stores': item['stores'] ?? 'Drip Emporium',
                  },
                )
                .toList();

        // Cache data
        await _database.delete(_productsTableName); // Clear old data
        for (var product in products) {
          await _database.insert(
            _productsTableName,
            product,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await prefs.setInt(
          _lastFetchTimestampKey,
          DateTime.now().millisecondsSinceEpoch,
        );
        print(
          'Successfully fetched and cached products from Google Sheet API.',
        );
        return products;
      } else {
        print('Failed to fetch from Google Sheet API: ${response.statusCode}');
        throw Exception(
          'Failed to load products. Server responded with status code ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching products: $e');
      throw Exception(
        'Network error: Could not connect to the product server. Error: $e',
      );
    }

    return []; // This line should ideally not be reached if exceptions are thrown
  }
}
