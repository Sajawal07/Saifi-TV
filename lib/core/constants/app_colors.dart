import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color background = Color(0xFF0D3B2A);
  static const Color primaryButton = Color(0xFFC9A84E);
  static const Color buttonText = Color(0xFF031A1A);
  static const Color headingText = Color(0xFFF5F3E7);
  static const Color card = Color(0xFF1D5338);
  static const Color border = Color(0xFFC9A84E);

  // Derived shades
  static const Color backgroundDark = Color(0xFF081F16);
  static const Color backgroundLight = Color(0xFF144835);
  static const Color cardDark = Color(0xFF163D29);
  static const Color cardLight = Color(0xFF246645);
  static const Color gold = Color(0xFFC9A84E);
  static const Color goldLight = Color(0xFFE8C97A);
  static const Color goldDark = Color(0xFF9E7A2F);
  static const Color textPrimary = Color(0xFFF5F3E7);
  static const Color textSecondary = Color(0xFFB8C4BB);
  static const Color textMuted = Color(0xFF7A9B87);
  static const Color divider = Color(0xFF2D6B47);
  static const Color success = Color(0xFF4CAF7D);
  static const Color error = Color(0xFFE57373);
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Colors.transparent;

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF144835), Color(0xFF0D3B2A)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8C97A), Color(0xFFC9A84E), Color(0xFF9E7A2F)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF246645), Color(0xFF1D5338)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D3B2A), Color(0xFF081F16)],
  );

  // Zikr Latifa Colors
  static const Color qalbColor = Color(0xFFE6C84A);       // Yellow/Gold
  static const Color ruhColor = Color(0xFFE53935);        // Red
  static const Color sirriColor = Color(0xFFF5F3E7);      // White
  static const Color khaffiColor = Color(0xFF212121);     // Black
  static const Color akhfaColor = Color(0xFF2E7D32);      // Green
  static const Color nufsColor = Color(0xFFF5F3E7);       // White
  static const Color sultanColor = Color(0xFFFFD700);     // Golden-White
}
