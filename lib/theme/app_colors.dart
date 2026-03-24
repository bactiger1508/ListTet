import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary - Đỏ Tết
  static const Color primary = Color(0xFFC62828);
  static const Color primaryDark = Color(0xFF8E0000);
  static const Color primaryLight = Color(0xFFFF5F52);
  static const Color primaryContainer = Color(0xFFFFCDD2);

  // Backgrounds
  static const Color background = Color(0xFFFFFFFF); // Trắng

  // Surfaces (Cards)
  static const Color cardDark = Color(0xFFFFFFFF); // Trắng
  static const Color cardDarker = Color(0xFFFAFAFA);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color surfaceDark = Color(0xFFEEEEEE);

  // Text
  static const Color textMain = Color(0xFF1F2937);
  static const Color textMain70 = Color(0xB31F2937);
  static const Color textMain54 = Color(0x8A1F2937);
  static const Color textMain24 = Color(0x3D1F2937);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textSecondary = Color(0xFF4B5563);

  // Accents
  static const Color accentGold = Color(0xFFFFD700); // Vàng Tài Lộc
  static const Color accentEmerald = Color(0xFF34D399); 
  static const Color accentRed = Color(0xFFC62828);

  // Status colors
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFFFC107); // Vàng cam highlight
  static const Color error = Color(0xFFD32F2F);

  // Borders & Shadows
  static const Color borderSubtle = Color(0xFFFFE082); // Vàng nhạt hơn cho viền
  static const Color borderMuted = Color(0xFFE5E7EB);
  
  // Premium Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFD32F2F), Color(0xFFC62828)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x33FFFFFF), Color(0x1AFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF9FAFB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Soft Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> deepShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.15),
      blurRadius: 20,
      spreadRadius: -4,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> goldShadow = [
    BoxShadow(
      color: accentGold.withValues(alpha: 0.3),
      blurRadius: 15,
      spreadRadius: -2,
      offset: const Offset(0, 6),
    ),
  ];
}
