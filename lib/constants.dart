import 'package:flutter/material.dart';


class AppAPI {
  static const String baseUrl = "https://ecofund-backend.onrender.com/api";
}

class AppColors {
static const Color primary = Color(0xFF1B5E20);       // Deep Eco Green
static const Color secondary = Color(0xFFFFA726);     // Warm Solar Gold
static const Color background = Color(0xFFFAFAFA);    // Soft Light Background
static const Color text = Color(0xFF212121);          // Neutral Text
static const Color accent = Color(0xFF4FC3F7);        // Light Sky Blue
static const Color white = Colors.white;
static const Color error = Colors.redAccent;
static const Gradient buttonGradient = LinearGradient(
  colors: [Color(0xFF81C784), Color(0xFF4CAF50)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
}

class AppSizes {
  static const double padding = 16.0;
  static const double borderRadius = 12.0;
  static const double buttonHeight = 48.0;
}

class AppStrings {
  static const String appName = "EcoFund";
  static const String loginTitle = "Welcome to EcoFund";
  static const String loginSubtitle = "Empowering Solar. Enabling Change.";
}

