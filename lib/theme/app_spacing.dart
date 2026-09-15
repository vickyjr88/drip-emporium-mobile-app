import 'package:flutter/material.dart';

/// 4pt scale shared across the redesign, plus the named zero-radius token
/// that enforces "no rounded corners" wherever a shape is needed ad hoc.
class AppSpacing {
  AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  static const hairline = 1.0;

  static const radiusZero = BorderRadius.zero;
}
