import 'package:flutter/material.dart';

/// 앱 전역 색상 정의
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF6B4EFF);
  static const Color primaryLight = Color(0xFF9D8AFF);
  static const Color primaryDark = Color(0xFF4B35B2);

  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F5);

  // Text Colors
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textHint = Color(0xFFADB5BD);

  // Semantic Colors
  static const Color success = Color(0xFF28A745);
  static const Color error = Color(0xFFDC3545);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF17A2B8);

  // Chat Colors
  static const Color userBubble = Color(0xFF6B4EFF);
  static const Color aiBubble = Color(0xFFF1F3F5);

  // Saju Element Colors (오행)
  static const Color wood = Color(0xFF28A745);   // 목 - 초록
  static const Color fire = Color(0xFFDC3545);   // 화 - 빨강
  static const Color earth = Color(0xFFFFC107); // 토 - 노랑
  static const Color metal = Color(0xFFFFFFFF); // 금 - 흰색
  static const Color water = Color(0xFF17A2B8); // 수 - 파랑
}
