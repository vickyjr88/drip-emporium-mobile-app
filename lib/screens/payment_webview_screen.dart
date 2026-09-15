import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/api_config.dart';
import '../theme/app_colors.dart';

/// Opens Paystack's checkout inside the app and watches for the return to
/// the storefront's confirmation page -- there is no dripemporium:// deep
/// link to intercept instead: Paystack's callback goes to a real web page
/// (backend/src/common/storefront-origin.ts + CheckoutService.start()), and
/// the app's old custom URI scheme was never actually reachable from it
/// (iOS registered no scheme at all for it). This screen is what makes
/// "return to the app after paying" work at all.
///
/// Pops with the reference string once the checkout-complete URL is
/// reached, or with null if the user backs out without paying. The caller
/// (CheckoutScreen) is the one that actually calls GET /checkout/verify --
/// this screen only recognises the URL, it never decides paid/unpaid itself.
class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({super.key, required this.authorizationUrl});

  final String authorizationUrl;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _returned = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
        onNavigationRequest: (request) {
          final completeUrl = '${ApiConfig.storefrontOrigin}${ApiConfig.checkoutCompletePath}';
          if (request.url.startsWith(completeUrl)) {
            _handleReturn(request.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  void _handleReturn(String url) {
    if (_returned) return; // onNavigationRequest can fire more than once
    _returned = true;
    final reference = Uri.parse(url).queryParameters['ref'];
    Navigator.of(context).pop(reference);
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel payment?'),
        content: const Text('Your order will be saved but not marked as paid. You can complete payment later.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('KEEP PAYING')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('CANCEL PAYMENT')),
        ],
      ),
    );
    // Backing out here is a deliberate "I did not finish paying" -- popping
    // with no reference is exactly the "not completed" signal CheckoutScreen
    // already expects from a plain back gesture, so it's reused verbatim.
    if (confirmed == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Backing out manually (the system back gesture/button, before reaching
    // the complete URL) is a deliberate "I did not finish paying" -- the
    // default pop already returns null to the caller, which is exactly the
    // "not completed" signal CheckoutScreen expects, so no PopScope
    // interception is needed here. The explicit close button below adds a
    // confirmation first since it's easier to hit by accident mid-payment.
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _confirmCancel,
        ),
        title: const Text('Complete payment'),
        titleTextStyle: Theme.of(context).textTheme.titleMedium,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              Uri.parse(widget.authorizationUrl).host,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 2,
            child: _loading
                ? const LinearProgressIndicator(minHeight: 2, color: AppColors.royal, backgroundColor: AppColors.de100)
                : null,
          ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
