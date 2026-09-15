import '../models/favorite_product.dart';
import 'api_client.dart';

/// Customer-JWT-guarded favorites. No local/guest fallback -- a favorite has
/// no meaning without an account (see FavoritesProvider), so every call here
/// requires ApiClient's token supplier to actually have a token.
class FavoritesRepository {
  FavoritesRepository(this._client);

  final ApiClient _client;

  Future<List<FavoriteProduct>> fetchFavorites() async {
    final response = await _client.get('/customer-portal/favorites');
    if (response is! List) return const [];
    return response.whereType<Map<String, dynamic>>().map(FavoriteProduct.fromJson).toList();
  }

  /// Idempotent server-side -- a duplicate tap is not an error.
  Future<void> addFavorite(String productId) {
    return _client.post('/customer-portal/favorites/$productId');
  }

  /// Also idempotent -- removing an already-removed favorite is a no-op.
  Future<void> removeFavorite(String productId) {
    return _client.delete('/customer-portal/favorites/$productId');
  }
}
