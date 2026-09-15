/// Non-secret configuration for talking to the real Drip Emporium backend.
///
/// Replaces `app_config.dart`, which held a live Paystack secret key
/// compiled into every shipped build -- there is no secret here at all: the
/// backend computes and charges the real amount server-side (see
/// CheckoutRepository), so the app never needs a payment credential of its
/// own.
class ApiConfig {
  ApiConfig._();

  /// Overridable at build time with
  /// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3100` (Android
  /// emulator's loopback to a host machine) for local backend development.
  /// Defaults to the real production API.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.dripemporium.store',
  );

  /// The storefront's own origin -- used to build real, shareable product
  /// links (`$storefrontOrigin/shop/<slug>`) and to recognise Paystack's
  /// checkout-complete redirect in the payment WebView.
  static const String storefrontOrigin = String.fromEnvironment(
    'STOREFRONT_ORIGIN',
    defaultValue: 'https://dripemporium.store',
  );

  /// Path (relative to [storefrontOrigin]) Paystack redirects to once a
  /// payment finishes -- see backend/src/common/storefront-origin.ts and
  /// CheckoutService.start(). The payment WebView watches for a URL
  /// starting with this to know checkout is done.
  static const String checkoutCompletePath = '/checkout/complete';

  /// The shop's real WhatsApp number, in the bare-digits form `wa.me` links
  /// expect (no leading `+`). This is the number already used correctly
  /// elsewhere in the app (main.dart's WhatsApp buttons); product_details_screen.dart
  /// currently has a different, placeholder number hardcoded -- that bug is
  /// fixed by routing every WhatsApp button through this single constant.
  static const String defaultWhatsAppNumber = '254113206481';
}
