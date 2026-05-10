import 'package:flutter/material.dart';

class ThemeHelper {
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getBackgroundColor(BuildContext context) {
    return isDarkMode(context) ? const Color(0xFF121212) : Colors.white;
  }

  static Color getCardColor(BuildContext context) {
    return isDarkMode(context) ? const Color(0xFF1E1E1E) : Colors.white;
  }

  static Color getTextColor(BuildContext context) {
    return isDarkMode(context) ? Colors.white : Colors.black87;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return isDarkMode(context) ? Colors.white70 : Colors.black54;
  }

  static Color getBorderColor(BuildContext context) {
    return isDarkMode(context) ? const Color(0xFF333333) : const Color(0xFFE8F5E8);
  }

  static Color getSurfaceColor(BuildContext context) {
    return isDarkMode(context) ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5);
  }

  static BoxShadow getCardShadow(BuildContext context) {
    return BoxShadow(
      color: isDarkMode(context) 
          ? Colors.black.withOpacity(0.3)
          : Colors.grey.withOpacity(0.1),
      spreadRadius: 1,
      blurRadius: 8,
      offset: const Offset(0, 2),
    );
  }
}