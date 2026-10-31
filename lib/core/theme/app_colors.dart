import 'package:flutter/material.dart';

/// Shared brand, surface, text, and semantic colors for Xelcart.
abstract final class AppColors {
  static const primary = Color(0xFF4F39F6);
  static const accent = Color(0xFFD9F99D);
  static const accentText = Color(0xFF365314);

  static const background = Color(0xFFF8F9FA);
  static const white = Color(0xFFFFFFFF);
  static const surface = white;
  static const cardBackground = white;
  static const border = Color(0xFFE5E7EB);

  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);

  static const pendingBackground = Color(0xFFFEF3C7);
  static const pendingText = Color(0xFFD97706);
  static const successBackground = Color(0xFFDCFCE7);
  static const successText = Color(0xFF15803D);
  static const confirmedBackground = successBackground;
  static const confirmedText = successText;
  static const processingBackground = Color(0xFFE0E7FF);
  static const processingText = Color(0xFF4338CA);
  static const inTransitBackground = processingBackground;
  static const inTransitText = processingText;
  static const warningBackground = Color(0xFFFED7AA);
  static const warningText = Color(0xFFC2410C);
  static const lowStockBackground = warningBackground;
  static const lowStockText = warningText;
  static const dangerBackground = Color(0xFFFEE2E2);
  static const dangerText = Color(0xFFDC2626);
  static const outOfStockBackground = dangerBackground;
  static const outOfStockText = dangerText;

  static const whatsapp = Color(0xFF25D366);
  static const instagram = Color(0xFFE1306C);
  static const facebook = Color(0xFF1877F2);
}
