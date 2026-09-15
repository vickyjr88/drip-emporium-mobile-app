import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Single light theme -- the central enforcement point for "no rounded
/// corners anywhere". Dark theme is out of scope (the web brand defines no
/// dark ramp); `MaterialApp` pins `themeMode: ThemeMode.light` so a device
/// in system dark mode doesn't fall back to a stock dark theme.
class AppTheme {
  AppTheme._();

  static final ShapeBorder _sharpCard = RoundedRectangleBorder(
    borderRadius: AppSpacing.radiusZero,
    side: const BorderSide(color: AppColors.line, width: AppSpacing.hairline),
  );

  static OutlineInputBorder _sharpInputBorder(Color color, {double width = AppSpacing.hairline}) {
    return OutlineInputBorder(
      borderRadius: AppSpacing.radiusZero,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.royal,
      onPrimary: AppColors.surface,
      secondary: AppColors.de500,
      onSecondary: AppColors.surface,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.danger,
      onError: AppColors.surface,
      outline: AppColors.line,
    );

    final textTheme = AppTypography.textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.paper,
      textTheme: textTheme,
      fontFamily: textTheme.bodyMedium?.fontFamily,

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: _sharpCard,
      ),

      appBarTheme: AppBarThemeData(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
        shape: const Border(bottom: BorderSide(color: AppColors.line, width: AppSpacing.hairline)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.royal,
          foregroundColor: AppColors.surface,
          disabledBackgroundColor: AppColors.de200,
          disabledForegroundColor: AppColors.surface,
          elevation: 0,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusZero),
          textStyle: AppTypography.buttonLabel(),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.royal,
          side: const BorderSide(color: AppColors.royal, width: AppSpacing.hairline),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusZero),
          textStyle: AppTypography.buttonLabel(color: AppColors.royal),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.royal,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusZero),
        ),
      ),

      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        border: _sharpInputBorder(AppColors.line),
        enabledBorder: _sharpInputBorder(AppColors.line),
        focusedBorder: _sharpInputBorder(AppColors.royal, width: 1.5),
        errorBorder: _sharpInputBorder(AppColors.danger),
        focusedErrorBorder: _sharpInputBorder(AppColors.danger, width: 1.5),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.royal,
        disabledColor: AppColors.de050,
        side: const BorderSide(color: AppColors.line, width: AppSpacing.hairline),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusZero),
        labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.ink),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: AppColors.surface),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusZero),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusZero),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.surface),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusZero),
        behavior: SnackBarBehavior.floating,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: AppSpacing.hairline,
        space: AppSpacing.hairline,
      ),

      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.danger,
        textColor: AppColors.surface,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.royal,
        linearTrackColor: AppColors.de100,
        circularTrackColor: AppColors.de100,
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusZero),
        iconColor: AppColors.royal,
        textColor: AppColors.ink,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.royal,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dividerColor: AppColors.line,
    );
  }
}
