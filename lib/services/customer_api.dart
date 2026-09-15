import '../models/customer_order.dart';
import '../models/customer_profile.dart';
import 'api_client.dart';

/// The result of a successful login/signup -- the token and the profile it
/// belongs to, matching what POST /customer-portal/login|signup return.
class AuthResult {
  const AuthResult({required this.accessToken, required this.customer});

  final String accessToken;
  final CustomerProfile customer;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['access_token']?.toString() ?? '',
      customer: CustomerProfile.fromJson(json['customer'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// Customer-portal auth and account calls. Deliberately thin -- session
/// state (the token, the ready flag, bootstrap-on-launch) lives in
/// CustomerAuthProvider, which calls through this.
class CustomerApi {
  CustomerApi(this._client);

  final ApiClient _client;

  Future<AuthResult> login(String email, String password) async {
    final response = await _client.post('/customer-portal/login', body: {'email': email, 'password': password});
    return AuthResult.fromJson(response as Map<String, dynamic>);
  }

  Future<AuthResult> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _client.post('/customer-portal/signup', body: {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'password': password,
    });
    return AuthResult.fromJson(response as Map<String, dynamic>);
  }

  Future<void> forgotPassword(String email) {
    return _client.post('/customer-portal/forgot-password', body: {'email': email});
  }

  Future<void> resetPassword(String token, String password) {
    return _client.post('/customer-portal/reset-password', body: {'token': token, 'password': password});
  }

  /// Re-validates the token server-side -- portalEnabled is checked on every
  /// call, so a revoked customer is rejected immediately, not just once at
  /// login. Throws ApiException (401, isUnauthorized) if the token is no
  /// longer valid.
  Future<CustomerProfile> me() async {
    final response = await _client.get('/customer-portal/me');
    return CustomerProfile.fromJson(response as Map<String, dynamic>);
  }

  Future<CustomerProfile> updateMe({String? firstName, String? lastName, String? phone, String? businessName}) async {
    final response = await _client.patch('/customer-portal/me', body: {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phone != null) 'phone': phone,
      if (businessName != null) 'businessName': businessName,
    });
    return CustomerProfile.fromJson(response as Map<String, dynamic>);
  }

  Future<List<CustomerOrder>> orders() async {
    final response = await _client.get('/customer-portal/orders');
    if (response is! List) return const [];
    return response.whereType<Map<String, dynamic>>().map(CustomerOrder.fromJson).toList();
  }

  Future<void> changePassword(String currentPassword, String newPassword) {
    return _client.post('/customer-portal/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}
