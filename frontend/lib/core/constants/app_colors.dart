import 'package:flutter/material.dart';

/// Modern Minimal Dark Theme Color Palette
/// Based on shadcn/ui zinc palette
abstract class AppColors {
  // ===== Background Colors (zinc scale) =====
  static const Color background = Color(0xFF09090B);      // zinc-950
  static const Color backgroundElevated = Color(0xFF0C0C0E); // slightly lighter

  // ===== Surface Colors =====
  static const Color surface = Color(0xFF18181B);         // zinc-900
  static const Color surfaceElevated = Color(0xFF1F1F23); // between 900-800
  static const Color surfaceHover = Color(0xFF27272A);    // zinc-800

  // ===== Border Colors =====
  static const Color border = Color(0xFF27272A);          // zinc-800
  static const Color borderSubtle = Color(0xFF1F1F23);    // subtle border

  // ===== Text Colors =====
  static const Color textPrimary = Color(0xFFFAFAFA);     // zinc-50
  static const Color textSecondary = Color(0xFFA1A1AA);   // zinc-400
  static const Color textMuted = Color(0xFF71717A);       // zinc-500
  static const Color textSubtle = Color(0xFF52525B);      // zinc-600

  // ===== Accent Color (single, subtle) =====
  static const Color accent = Color(0xFF8B5CF6);          // violet-500
  static const Color accentMuted = Color(0xFF7C3AED);     // violet-600
  static const Color accentSubtle = Color(0xFF6D28D9);    // violet-700

  // ===== Element Colors (muted, sophisticated) =====
  static const Color wood = Color(0xFF4ADE80);            // green-400
  static const Color fire = Color(0xFFF87171);            // red-400
  static const Color earth = Color(0xFFFBBF24);           // amber-400
  static const Color metal = Color(0xFFE5E7EB);           // gray-200
  static const Color water = Color(0xFF60A5FA);           // blue-400

  // ===== Semantic Colors =====
  static const Color success = Color(0xFF22C55E);         // green-500
  static const Color warning = Color(0xFFF59E0B);         // amber-500
  static const Color error = Color(0xFFEF4444);           // red-500
  static const Color info = Color(0xFF3B82F6);            // blue-500

  // ===== Chart/Score Colors =====
  static const Color scoreHigh = Color(0xFF4ADE80);       // green
  static const Color scoreMedium = Color(0xFFFBBF24);     // amber
  static const Color scoreLow = Color(0xFFF87171);        // red

  // ===== Gradient helpers =====
  static const List<Color> accentGradient = [
    Color(0xFF8B5CF6),
    Color(0xFF6366F1),
  ];

  // ===== Legacy support =====
  static const Color primary = accent;
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = accentSubtle;
  static const Color secondary = Color(0xFFFBBF24);
  static const Color divider = border;
}
