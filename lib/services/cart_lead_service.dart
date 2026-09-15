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
      'lines': _linesJson(lines),
      if (customerName != null) 'customerName': customerName,
      if (customerPhone != null) 'customerPhone': customerPhone,
      if (customerEmail != null) 'customerEmail': customerEmail,
      if (shippingAddress != null) 'shippingAddress': shippingAddress,
      if (message != null) 'message': message,
      if (referralCode != null) 'referralCode': referralCode,
      if (campaignCode != null) 'campaignCode': campaignCode,
    });
  }

  /// Periodic snapshot of a cart that's been left with contact details
  /// filled in but no order placed yet -- the backend dedupes by
  /// email/phone against any existing `NEW` `ABANDONED_CART` lead for the
  /// same contact, so calling this repeatedly as the shopper keeps typing
  /// just updates one row rather than creating duplicates. Requires phone
  /// or email, matching the backend's own requirement; callers should also
  /// debounce (the web storefront waits ~2s after the last keystroke) so
  /// this isn't fired on every character typed.
  Future<void> syncAbandoned({
    required List<CartLine> lines,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? shippingAddress,
    int? shipping,
    String? referralCode,
    String? campaignCode,
  }) {
    return _client.post('/cart-leads/abandoned-sync', body: {
      'source': 'ABANDONED_CART',
      'lines': _linesJson(lines),
      if (customerName != null) 'customerName': customerName,
      if (customerPhone != null) 'customerPhone': customerPhone,
      if (customerEmail != null) 'customerEmail': customerEmail,
      if (shippingAddress != null) 'shippingAddress': shippingAddress,
      if (shipping != null) 'shipping': shipping,
      if (referralCode != null) 'referralCode': referralCode,
      if (campaignCode != null) 'campaignCode': campaignCode,
    });
  }

  List<Map<String, dynamic>> _linesJson(List<CartLine> lines) {
    return lines
        .map((line) => {
              'variantId': line.variantId,
              'sku': line.sku,
              'name': line.name,
              'size': line.size,
              'quantity': line.quantity,
              'priceKes': line.priceKes,
            })
        .toList();
  }
}
