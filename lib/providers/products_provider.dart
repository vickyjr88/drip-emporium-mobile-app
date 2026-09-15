import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/shop_category.dart';
import '../services/shop_repository.dart';

/// The product grid's state, rewritten against the real API.
///
/// Filtering is server-side (`?category=`, `?search=`) -- there is no local
/// "stores" concept at all, which is the root-cause fix for the bug that
/// silently filtered the whole feed to zero: the old provider matched a
/// `stores` field the live feed no longer emits, against a hardcoded default
/// that was often not even a member of the set of values actually present.
/// The real API has no such field to filter on.
class ProductsProvider with ChangeNotifier {
  ProductsProvider(this._repository);

  final ShopRepository _repository;

  List<Product> _products = [];
  List<ShopCategory> _categories = [];
  bool _isLoading = false;
  /// Distinguished from "no results for this filter" -- conflating the two
  /// is exactly how the original bug went unnoticed for so long. Null means
  /// the last fetch succeeded (whether or not it returned any products).
  String? _error;
  String? _selectedCategory; // null = all
  String _search = '';

  Timer? _searchDebounce;
  // Guards against an out-of-order slow response overwriting a newer fast
  // one, e.g. typing "sneak" then "sneaker" quickly -- the response for
  // "sneak" must never land after and replace "sneaker"'s results.
  int _requestId = 0;

  List<Product> get products => _products;
  List<ShopCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedCategory => _selectedCategory;
  String get search => _search;

  Future<void> load() async {
    await Future.wait([_fetchCategories(), _fetchProducts()]);
  }

  Future<void> refresh() => _fetchProducts();

  Future<void> _fetchCategories() async {
    _categories = await _repository.fetchCategories();
    notifyListeners();
  }

  Future<void> _fetchProducts() async {
    final requestId = ++_requestId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _repository.fetchProducts(
        category: _selectedCategory,
        search: _search.isEmpty ? null : _search,
      );
      if (requestId != _requestId) return; // superseded by a newer request
      _products = results;
    } catch (_) {
      if (requestId != _requestId) return;
      _error = 'Could not load products. Check your connection and try again.';
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Debounced 350ms so fast typing sends one request per pause rather than
  /// one per keystroke.
  void setSearch(String query) {
    _search = query.trim();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _fetchProducts);
  }

  /// A category tap should feel instant -- no debounce.
  void setCategory(String? slug) {
    // "all" is the explicit "everything" choice, kept distinct from a null
    // category (no filter selected yet) so a bookmark/deep link to it is
    // unambiguous -- mirrors the web storefront's resolveShopCategory().
    _selectedCategory = slug == 'all' ? null : slug;
    unawaited(_fetchProducts());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
