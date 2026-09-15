import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Libre Caslon Text (serif, 400/700) for display/headings, Manrope (sans,
/// 400/500/700/800) for body/UI -- the exact pairing the web storefront
/// uses. Both are bundled as local variable-font assets (see pubspec.yaml
/// `fonts:`) and referenced here by family name directly -- deliberately
/// not via `GoogleFonts.manrope()`/`.libreCaslonText()`, since those
/// helpers look for fonts pre-bundled under the package's own naming
/// convention, not an app's plain pubspec `fonts:` declaration, and would
/// otherwise fall through to a runtime HTTP fetch.
class AppTypography {
  AppTypography._();

  static const _serifFamily = 'Libre Caslon Text';
  static const _sansFamily = 'Manrope';

  static TextStyle _serif({
    required double fontSize,
    required FontWeight fontWeight,
    Color color = AppColors.ink,
    double? height,
  }) {
    return TextStyle(
      fontFamily: _serifFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static TextStyle _sans({
    required double fontSize,
    required FontWeight fontWeight,
    Color color = AppColors.ink,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: _sansFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Manrope 800, uppercase-tracked -- the `.lp-button` language from the
  /// web brand. Letter spacing is `fontSize * 0.12` (CSS `em` is relative to
  /// font size; Flutter's is absolute logical pixels).
  static TextStyle buttonLabel({double fontSize = 11, Color? color}) {
    return _sans(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      color: color ?? AppColors.surface,
      letterSpacing: fontSize * 0.12,
    );
  }

  static TextTheme get textTheme => TextTheme(
        displayLarge: _serif(fontSize: 40, fontWeight: FontWeight.w700, height: 1.1),
        displayMedium: _serif(fontSize: 32, fontWeight: FontWeight.w700, height: 1.15),
        displaySmall: _serif(fontSize: 28, fontWeight: FontWeight.w700, height: 1.15),
        headlineLarge: _serif(fontSize: 24, fontWeight: FontWeight.w700),
        headlineMedium: _serif(fontSize: 20, fontWeight: FontWeight.w700),
        headlineSmall: _serif(fontSize: 18, fontWeight: FontWeight.w700),
        titleLarge: _serif(fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: _sans(fontSize: 16, fontWeight: FontWeight.w700),
        titleSmall: _sans(fontSize: 14, fontWeight: FontWeight.w700),
        bodyLarge: _sans(fontSize: 16, fontWeight: FontWeight.w400, height: 1.4),
        bodyMedium: _sans(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4),
        bodySmall: _sans(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.muted),
        labelLarge: _sans(fontSize: 14, fontWeight: FontWeight.w700),
        labelMedium: _sans(fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: _sans(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted),
      );
}
