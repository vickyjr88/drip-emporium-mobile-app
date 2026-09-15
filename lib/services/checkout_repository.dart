import '../models/customer_order.dart';
import 'api_client.dart';

class CheckoutLine {
  const CheckoutLine({required this.variantId, required this.quantity});

  final String variantId;
  final int quantity;

  Map<String, dynamic> toJson() => {'variantId': variantId, 'quantity': quantity};
}

/// What POST /checkout returns -- an authorizationUrl to open in the payment
/// WebView, never a Paystack key of any kind. The backend prices every line
/// from the database and computes the real charge; the app has no way to
/// under-report what's owed, unlike the old client-side Paystack call.
class CheckoutSession {
  const CheckoutSession({required this.orderNumber, required this.total, required this.authorizationUrl, required this.reference});

  final String orderNumber;
  final num total;
  final String authorizationUrl;
  final String reference;

  factory CheckoutSession.fromJson(Map<String, dynamic> json) {
    return CheckoutSession(
      orderNumber: json['orderNumber']?.toString() ?? '',
      total: json['total'] is num ? json['total'] as num : num.tryParse(json['total']?.toString() ?? '') ?? 0,
      authorizationUrl: json['authorizationUrl']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
    );
  }
}

class CheckoutVerifyResult {
  const CheckoutVerifyResult({required this.orderNumber, required this.status, required this.paid});

  final String orderNumber;
  final String status;
  final bool paid;

  factory CheckoutVerifyResult.fromJson(Map<String, dynamic> json) {
    return CheckoutVerifyResult(
      orderNumber: json['orderNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      paid: json['paid'] == true,
    );
  }
}

class CheckoutRepository {
  CheckoutRepository(this._client);

  final ApiClient _client;

  /// Whether Paystack is configured server-side -- if false, the pay-online
  /// path should be hidden rather than offering a button that will fail.
  Future<bool> fetchConfig() async {
    try {
      final response = await _client.get('/checkout/config');
      return response is Map<String, dynamic> && response['online'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Sends the bearer token when the caller is signed in (via ApiClient's
  /// token supplier) -- that's what activates tier pricing server-side.
  /// Guest checkout (no token) is a fully supported, first-class path.
  Future<CheckoutSession> startCheckout({
    required List<CheckoutLine> lines,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? shippingAddress,
    String? password,
    String? referralCode,
  }) async {
    final response = await _client.post('/checkout', body: {
      'lines': lines.map((line) => line.toJson()).toList(),
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      if (shippingAddress != null && shippingAddress.isNotEmpty) 'shippingAddress': shippingAddress,
      if (password != null && password.isNotEmpty) 'password': password,
      if (referralCode != null && referralCode.isNotEmpty) 'referralCode': referralCode,
    });
    return CheckoutSession.fromJson(response as Map<String, dynamic>);
  }

  Future<CheckoutVerifyResult> verify(String reference) async {
    final response = await _client.get('/checkout/verify', query: {'reference': reference});
    return CheckoutVerifyResult.fromJson(response as Map<String, dynamic>);
  }

  /// Guest-safe order lookup -- no auth required, matches how a shopper can
  /// return to a confirmation page without being signed in.
  Future<CustomerOrder?> lookupOrder(String reference) async {
    try {
      final response = await _client.get('/checkout/orders/$reference');
      if (response is! Map<String, dynamic>) return null;
      return CustomerOrder.fromJson(response);
    } on ApiException {
      return null;
    }
  }

  Future<void> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) {
    return _client.post('/checkout/signup', body: {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'password': password,
    });
  }
}
