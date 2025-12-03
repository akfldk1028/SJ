import 'package:flutter/material.dart';

/// 앱 컬러 팔레트
abstract class AppColors {
  // Primary Colors - 사주/운세 느낌의 딥 퍼플/인디고 계열
  static const Color primary = Color(0xFF5C6BC0);
  static const Color primaryLight = Color(0xFF8E99A4);
  static const Color primaryDark = Color(0xFF3949AB);

  // Secondary Colors - 골드 계열 (운세/행운 느낌)
  static const Color secondary = Color(0xFFFFB300);
  static const Color secondaryLight = Color(0xFFFFE54C);
  static const Color secondaryDark = Color(0xFFC68400);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Chat Bubble Colors
  static const Color userBubble = Color(0xFF5C6BC0);
  static const Color aiBubble = Color(0xFFE8EAF6);
  static const Color aiBubbleDark = Color(0xFF303F9F);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Divider
  static const Color divider = Color(0xFFBDBDBD);
}
