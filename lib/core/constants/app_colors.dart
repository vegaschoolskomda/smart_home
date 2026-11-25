import 'package:flutter/material.dart';

/// App color palette matching the modern smart home design direction
class AppColors {
  AppColors._();

  // Background & Surfaces
  static const Color background = Color(0xFFF4F6F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE5EAF0);
  static const Color divider = Color(0xFFEBF0F5);

  // Hero Card Dark Navy
  static const Color heroNavy = Color(0xFF13253A);
  static const Color heroNavyLight = Color(0xFF1B3450);
  static const Color heroSubtitle = Color(0xFFB0C4D6);

  // Teal / Cyan Accent (matching the reference)
  static const Color tealPrimary = Color(0xFF0EA5A5);
  static const Color tealDark = Color(0xFF0A7C7C);
  static const Color tealLight = Color(0xFFE8F7F9);
  static const Color tealBorder = Color(0xFFD0EFF2);

  // Typography
  static const Color textDark = Color(0xFF101E2E);
  static const Color textMuted = Color(0xFF7A8B9E);
  static const Color textLight = Color(0xFF9BB2C7);

  // Status Indicators
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFE8F8EE);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFF7E6);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);

  // Backward compatibility aliases
  static const Color primary = tealPrimary;
  static const Color primaryLight = tealLight;
  static const Color textPrimary = textDark;
  static const Color textSecondary = textMuted;
  static const Color border = cardBorder;
}
