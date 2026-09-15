import '../models/cart_line.dart';
import 'api_client.dart';

/// Analytics/lead capture for the WhatsApp sales channel -- most of this
/// shop's real sales close in a WhatsApp chat, not online checkout, so this
/// is what makes the app's contribution visible in the same funnel as web.
///
/// Every call here is fire-and-forget: `.catchError` at the call site (not
/// awaited in a way that blocks the UI). A failed analytics call must never
/// break or delay a sale.
class CartLeadService {
  CartLeadService(this._client);

  final ApiClient _client;

  /// Fired on every WhatsApp tap -- the floating button, "ask about
  /// sizes", a product page's WhatsApp button -- regardless of whether the
  /// shopper goes on to type anything. `source` should be short and
  /// specific, e.g. "product-page", "cart", "float".
  Future<void> recordWhatsAppClick({required String source, String? referralCode, String? campaignCode}) {
    return _client.post('/cart-leads/whatsapp-click', body: {
      'source': source,
      if (referralCode != null) 'referralCode': referralCode,
      if (campaignCode != null) 'campaignCode': campaignCode,
    });
  }

  /// Recorded when a shopper actually takes the WhatsApp-order route instead
  /// of paying online -- requires at least one way to reach them (name,
  /// phone, or email), matching the backend's own requirement.
  Future<void> recordWhatsAppOrder({
    required List<CartLine> lines,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? shippingAddress,
    String? message,
    String? referralCode,
    String? campaignCode,
  }) {
    return _client.post('/cart-leads', body: {
      'source': 'WHATSAPP_ORDER',
      'lines': lines
          .map((line) => {
                'variantId': line.variantId,
                'sku': line.sku,
                'name': line.name,
                'size': line.size,
                'quantity': line.quantity,
                'priceKes': line.priceKes,
              })
          .toList(),
      if (customerName != null) 'customerName': customerName,
      if (customerPhone != null) 'customerPhone': customerPhone,
      if (customerEmail != null) 'customerEmail': customerEmail,
      if (shippingAddress != null) 'shippingAddress': shippingAddress,
      if (message != null) 'message': message,
      if (referralCode != null) 'referralCode': referralCode,
      if (campaignCode != null) 'campaignCode': campaignCode,
    });
  }
}
