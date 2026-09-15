import 'package:flutter/material.dart';

/// Named 1:1 after the web storefront's brand ramp in `web/app/globals.css`
/// (`--de-900`...`--de-050`). Deliberately explicit constants, not
/// `ColorScheme.fromSeed` -- a generated tonal palette would re-derive its
/// own values and stop matching these exact brand hexes.
class AppColors {
  AppColors._();

  static const de900 = Color(0xFF020721);
  static const de800 = Color(0xFF06166E);
  static const de700 = Color(0xFF0D2088);
  static const de600 = Color(0xFF172688);
  static const de500 = Color(0xFF2438A8);
  static const de400 = Color(0xFF4A5CC4);

  /// Surfaces/borders only below this point -- not enough contrast on white
  /// for body text.
  static const de300 = Color(0xFF8A95DC);
  static const de200 = Color(0xFFC3C9EE);
  static const de100 = Color(0xFFE8EAF8);
  static const de050 = Color(0xFFF4F5FC);

  static const ink = de900;
  static const muted = Color(0xFF5B6480);
  static const line = Color(0xFFDFE2F0);
  static const paper = de050;
  static const royal = de800;
  static const go = Color(0xFF0F7A40);

  static const surface = Colors.white;

  /// Darker than `Colors.red` for adequate contrast on white.
  static const danger = Color(0xFFB3261E);

  /// Darker than `Colors.orange`, which fails contrast on white.
  static const warning = Color(0xFFA85B00);
}
