import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Trainova brand colors
  static const Color primary =
      Color(0xFF5D54C0); // Slightly adjusted purple for Trainova brand
  static const Color primaryDark = Color(0xFF4A43A0); // Darker shade
  static const Color primaryLight = Color(0xFF7069D8); // Lighter shade

  // Secondary colors - Accent colors for Trainova
  static const Color secondary =
      Color(0xFF42D6D6); // Turquoise for Trainova accents
  static const Color secondaryDark = Color(0xFF38B6B6); // Darker turquoise
  static const Color secondaryLight = Color(0xFF5EEDED); // Lighter turquoise

  // Light mode colors
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightCardBackground = Colors.white;
  static const Color lightTextPrimary = Color(0xFF212529);
  static const Color lightTextSecondary = Color(0xFF6C757D);
  static const Color lightTextLight = Color(0xFFADB5BD);

  // Dark mode colors
  static const Color darkBackground = Color(0xFF212529);
  static const Color darkCardBackground = Color(0xFF343A40);
  static const Color darkTextPrimary = Color(0xFFF8F9FA);
  static const Color darkTextSecondary = Color(0xFFCED4DA);
  static const Color darkTextLight = Color(0xFF6C757D);

  // Legacy colors (for backward compatibility)
  static const Color background = lightBackground;
  static const Color cardBackground = lightCardBackground;
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color textLight = lightTextLight;
}
