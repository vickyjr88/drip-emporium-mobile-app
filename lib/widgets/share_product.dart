import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Shares [text], anchored to the tapped [context]'s render box.
///
/// `share_plus` on this iOS/simulator combination throws
/// `sharePositionOrigin: argument must be set` when the rect is omitted or
/// zero-sized -- despite the package's own docs describing it as iPad/Mac
/// only, this build's iOS share sheet requires a real, non-zero origin
/// rect. Deriving it from the button that was tapped keeps the share sheet's
/// popover anchored sensibly on iPad too.
Future<void> shareProduct(BuildContext context, String text) async {
  final box = context.findRenderObject() as RenderBox?;
  final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : Rect.zero;

  try {
    await SharePlus.instance.share(ShareParams(
      text: text,
      sharePositionOrigin: origin.isEmpty ? null : origin,
    ));
  } catch (e) {
    debugPrint('Share failed: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the share sheet.')),
      );
    }
  }
}
