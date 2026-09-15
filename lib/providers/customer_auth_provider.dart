import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer_profile.dart';
import '../services/api_client.dart';
import '../services/customer_api.dart';

const _tokenKey = 'de_customer_token';
const _profileCacheKey = 'de_customer_profile_cache';

/// Customer session state, mirroring the web storefront's customer-auth.tsx
/// contract (ready/token/customer/login/signup/logout/refresh).
///
/// The token lives in flutter_secure_storage (Keychain/Keystore-backed) --
/// not SharedPreferences, which on Android is a world-readable-by-root
/// plaintext XML file, and this token grants access to order history and
/// PII. The profile itself is non-sensitive and cached in SharedPreferences
/// so the UI can render signed-in state instantly on cold start, before the
/// network re-validation below completes.
class CustomerAuthProvider extends ChangeNotifier {
  CustomerAuthProvider(this._api) {
    unawaited(_bootstrap());
  }

  final CustomerApi _api;
  final _secureStorage = const FlutterSecureStorage();

  /// False until bootstrap has resolved -- gate any auth-dependent UI on
  /// this to avoid a signed-out flash while the token is still being read.
  bool ready = false;
  String? token;
  CustomerProfile? customer;

  bool get isSignedIn => token != null;

  /// Wired into ApiClient's tokenSupplier so every repository call carries
  /// the current token automatically, without each one needing a reference
  /// to this provider.
  String? tokenSupplier() => token;

  Future<void> _bootstrap() async {
    try {
      final savedToken = await _secureStorage.read(key: _tokenKey);
      if (savedToken == null || savedToken.isEmpty) {
        ready = true;
        notifyListeners();
        return;
      }

      token = savedToken;
      // Restore the cached profile optimistically so the UI renders
      // signed-in immediately, before the network round trip below settles.
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_profileCacheKey);
      if (cachedJson != null) {
        try {
          customer = CustomerProfile.fromJson(jsonDecode(cachedJson) as Map<String, dynamic>);
          notifyListeners();
        } catch (_) {
          // Corrupt cache -- ignored, the network call below is authoritative.
        }
      }

      try {
        final freshProfile = await _api.me();
        customer = freshProfile;
        await _cacheProfile(freshProfile);
      } on ApiException catch (error) {
        // The server revokes portalEnabled immediately -- a 401 here means
        // this session is genuinely no longer valid, so it must be cleared.
        if (error.isUnauthorized) {
          await _clearSession();
        }
        // Any other API error (5xx, a malformed response) is treated the
        // same as a network error below: keep the cached session rather
        // than signing the person out over a server hiccup.
      } catch (_) {
        // A network error (no connectivity, timeout) must NOT sign the
        // customer out -- a subway ride should not end their session. This
        // is a deliberate divergence from the web client, which clears on
        // any error; that is wrong for mobile connectivity.
      }
    } finally {
      ready = true;
      notifyListeners();
    }
  }

  Future<void> _cacheProfile(CustomerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileCacheKey, jsonEncode(profile.toJson()));
  }

  Future<void> _adopt(AuthResult result) async {
    token = result.accessToken;
    customer = result.customer;
    await _secureStorage.write(key: _tokenKey, value: result.accessToken);
    await _cacheProfile(result.customer);
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _adopt(await _api.login(email, password));
  }

  Future<void> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _adopt(await _api.signup(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      password: password,
    ));
  }

  Future<void> _clearSession() async {
    token = null;
    customer = null;
    await _secureStorage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileCacheKey);
  }

  /// Does NOT clear the cart -- a guest cart is still a valid cart, and
  /// signing out should not throw away items someone was about to buy.
  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  Future<void> refresh() async {
    if (token == null) return;
    try {
      customer = await _api.me();
      await _cacheProfile(customer!);
      notifyListeners();
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await logout();
      }
    } catch (_) {
      // Network error -- keep the existing session, same reasoning as bootstrap.
    }
  }
}
