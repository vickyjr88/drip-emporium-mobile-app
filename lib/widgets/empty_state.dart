import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum EmptyStateGlyph { cart, box, heart, search }

/// Shared empty-state layout: hand-drawn line-art icon, title, message, and
/// an optional action button. Used wherever a screen previously showed a
/// bare `Text('No ... found')`.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.glyph,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final EmptyStateGlyph glyph;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: CustomPaint(painter: _EmptyStatePainter(glyph)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!.toUpperCase()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Sharp-edged, square-capped line art in brand navy -- deliberately hand
/// drawn instead of pulling in an SVG dependency for four small graphics;
/// the sharp-line look also matches the brand better than typical rounded
/// illustration art.
class _EmptyStatePainter extends CustomPainter {
  _EmptyStatePainter(this.glyph);

  final EmptyStateGlyph glyph;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.de300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    switch (glyph) {
      case EmptyStateGlyph.cart:
        _paintCart(canvas, size, paint);
      case EmptyStateGlyph.box:
        _paintBox(canvas, size, paint);
      case EmptyStateGlyph.heart:
        _paintHeart(canvas, size, paint);
      case EmptyStateGlyph.search:
        _paintSearch(canvas, size, paint);
    }
  }

  void _paintCart(Canvas canvas, Size size, Paint paint) {
    final w = size.width, h = size.height;
    final body = Path()
      ..moveTo(w * 0.18, h * 0.28)
      ..lineTo(w * 0.82, h * 0.28)
      ..lineTo(w * 0.72, h * 0.68)
      ..lineTo(w * 0.28, h * 0.68)
      ..close();
    canvas.drawPath(body, paint);
    canvas.drawLine(Offset(w * 0.10, h * 0.18), Offset(w * 0.18, h * 0.28), paint);
    canvas.drawLine(Offset(w * 0.02, h * 0.18), Offset(w * 0.10, h * 0.18), paint);
    canvas.drawCircle(Offset(w * 0.36, h * 0.82), w * 0.06, paint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.82), w * 0.06, paint);
  }

  void _paintBox(Canvas canvas, Size size, Paint paint) {
    final w = size.width, h = size.height;
    final rect = Rect.fromLTWH(w * 0.14, h * 0.32, w * 0.72, h * 0.5);
    canvas.drawRect(rect, paint);
    canvas.drawLine(Offset(w * 0.14, h * 0.32), Offset(w * 0.5, h * 0.14), paint);
    canvas.drawLine(Offset(w * 0.86, h * 0.32), Offset(w * 0.5, h * 0.14), paint);
    canvas.drawLine(Offset(w * 0.5, h * 0.14), Offset(w * 0.5, h * 0.82), paint);
  }

  void _paintHeart(Canvas canvas, Size size, Paint paint) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, h * 0.78)
      ..lineTo(w * 0.22, h * 0.48)
      ..cubicTo(w * 0.06, h * 0.30, w * 0.22, h * 0.10, w * 0.5, h * 0.28)
      ..cubicTo(w * 0.78, h * 0.10, w * 0.94, h * 0.30, w * 0.78, h * 0.48)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _paintSearch(Canvas canvas, Size size, Paint paint) {
    final w = size.width, h = size.height;
    canvas.drawCircle(Offset(w * 0.42, h * 0.42), w * 0.26, paint);
    canvas.drawLine(Offset(w * 0.62, h * 0.62), Offset(w * 0.86, h * 0.86), paint);
  }

  @override
  bool shouldRepaint(covariant _EmptyStatePainter oldDelegate) => oldDelegate.glyph != glyph;
}
