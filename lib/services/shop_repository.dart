import '../models/product.dart';
import '../models/shop_category.dart';
import 'api_client.dart';

/// Read-only catalogue access. Secondary rails (featured, categories,
/// filters) fall back to empty on failure -- a shop window missing one
/// section still sells. The main product list does NOT fall back silently:
/// it rethrows, so the caller can show a real retry action instead of the
/// "No products found" that hid the old stores-filter bug for so long.
class ShopRepository {
  ShopRepository(this._client);

  final ApiClient _client;

  Future<List<Product>> fetchProducts({
    String? category,
    String? brand,
    String? size,
    String? search,
    num? minPrice,
    num? maxPrice,
    bool? inStockOnly,
    String? sort,
  }) async {
    final response = await _client.get('/shop/products', query: {
      'category': category,
      'brand': brand,
      'size': size,
      'search': search,
      'minPrice': minPrice?.toString(),
      'maxPrice': maxPrice?.toString(),
      'inStockOnly': inStockOnly == true ? 'true' : null,
      'sort': sort,
    });
    if (response is! List) return const [];
    return response.whereType<Map<String, dynamic>>().map(Product.fromJson).toList();
  }

  Future<List<Product>> fetchFeatured({int limit = 10}) async {
    try {
      final response = await _client.get('/shop/products/featured', query: {'limit': limit.toString()});
      if (response is! List) return const [];
      return response.whereType<Map<String, dynamic>>().map(Product.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<Product?> fetchProduct(String slug) async {
    try {
      final response = await _client.get('/shop/products/$slug');
      if (response is! Map<String, dynamic>) return null;
      return Product.fromJson(response);
    } on ApiException {
      return null;
    }
  }

  Future<List<ShopCategory>> fetchCategories() async {
    try {
      final response = await _client.get('/shop/categories');
      if (response is! List) return const [];
      return response.whereType<Map<String, dynamic>>().map(ShopCategory.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  /// {brands: [...], sizes: [...]}
  Future<({List<String> brands, List<String> sizes})> fetchFilters() async {
    try {
      final response = await _client.get('/shop/filters');
      if (response is! Map<String, dynamic>) return (brands: <String>[], sizes: <String>[]);
      final brands = (response['brands'] as List?)?.whereType<String>().toList() ?? <String>[];
      final sizes = (response['sizes'] as List?)?.whereType<String>().toList() ?? <String>[];
      return (brands: brands, sizes: sizes);
    } catch (_) {
      return (brands: <String>[], sizes: <String>[]);
    }
  }
}
