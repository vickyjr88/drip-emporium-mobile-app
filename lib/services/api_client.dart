import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thrown for any non-2xx response. `message` unwraps Nest's
/// `{message: string | string[]}` validation-error shape (see
/// customer-auth.tsx:68-71 on the web side, which this mirrors) so a caller
/// can show the backend's actual reason rather than a generic failure.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Thin HTTP wrapper around the real Drip Emporium API. Deliberately only
/// speaks HTTP -- it has no idea what a product or a customer is; that
/// belongs to the repositories built on top of it (ShopRepository,
/// CheckoutRepository, CustomerApi, FavoritesRepository).
///
/// The token is read via a callback rather than stored as a field: storing a
/// copy risks this client silently using a stale token after
/// CustomerAuthProvider logs out or refreshes it, and a callback also avoids
/// a circular constructor dependency (the auth provider needs an ApiClient
/// to make its own calls, so ApiClient cannot depend on the auth provider
/// directly).
class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client, String? Function()? tokenSupplier})
      : _client = client ?? http.Client(),
        _tokenSupplier = tokenSupplier;

  final String baseUrl;
  final http.Client _client;
  final String? Function()? _tokenSupplier;

  Uri _uri(String path, [Map<String, String?>? query]) {
    // Null/empty values are dropped rather than sent as `?category=` --
    // an empty query param is not the same thing as "no filter" to some
    // backends, and it is simpler to never send it than to rely on the
    // server treating both the same way.
    final filtered = <String, String>{};
    query?.forEach((key, value) {
      if (value != null && value.isNotEmpty) filtered[key] = value;
    });
    return Uri.parse('$baseUrl$path').replace(
      queryParameters: filtered.isEmpty ? null : filtered,
    );
  }

  Map<String, String> _headers() {
    final token = _tokenSupplier?.call();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _decode(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  dynamic _handle(http.Response response) {
    final decoded = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;

    String message = 'Something went wrong. Try again.';
    if (decoded is Map && decoded['message'] != null) {
      final raw = decoded['message'];
      message = raw is List ? (raw.isNotEmpty ? raw.first.toString() : message) : raw.toString();
    }
    throw ApiException(response.statusCode, message);
  }

  Future<dynamic> get(String path, {Map<String, String?>? query}) async {
    final response = await _client.get(_uri(path, query), headers: _headers());
    return _handle(response);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(response);
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    final response = await _client.patch(
      _uri(path),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await _client.delete(_uri(path), headers: _headers());
    return _handle(response);
  }
}
