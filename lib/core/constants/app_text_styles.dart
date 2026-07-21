import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const String _fontFamily = 'Amiri';

  // Display
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: AppColors.headingText,
    letterSpacing: 0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.headingText,
    letterSpacing: 0.3,
  );

  // Heading
  static const TextStyle headingLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.headingText,
    letterSpacing: 0.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.headingText,
  );

  static const TextStyle headingSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.headingText,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    color: AppColors.textMuted,
    height: 1.5,
  );

  // Gold accent
  static const TextStyle goldText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.gold,
    letterSpacing: 0.3,
  );

  static const TextStyle goldSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.gold,
    letterSpacing: 0.2,
  );

  // Button
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.buttonText,
    letterSpacing: 0.5,
  );

  // Arabic
  static const TextStyle arabicLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w600,
    height: 1.6,
  );

  static const TextStyle arabic = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  // Caption / Label
  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: 0.8,
  );
}
