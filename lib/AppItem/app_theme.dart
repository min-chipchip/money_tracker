import 'package:flutter/material.dart';

/// Every color the app uses. Change a color here and it changes everywhere.
class AppColors {
  AppColors._();

  static const Color primary = Colors.blue;
  static const Color primaryLight = Color(0xFF90CAF9); // blue 200
  static const Color primarySoft = Color(0xFFBBDEFB); // blue 100
  static const Color accent = Color(0xFF64B5F6); // blue 300

  static const Color background = Color(0xFFF0F9FF);
  static const Color surface = Colors.white;
  static const Color fieldFill = Color(0xFFF5F5F5); // grey 100
  static const Color inactive = Color(0xFFEEEEEE); // grey 200
  static const Color muted = Color(0xFF757575); // grey 600

  static const Color star = Color(0xFFF9A825); // yellow 800
  static const Color starOff = Color(0xFFBDBDBD); // grey 400
  static const Color success = Color(0xFF66BB6A); // green 400
  static const Color income = Color(0xFF2E7D32); // green 800, readable as text
  static const Color error = Color(0xFFE57373); // red 300

  /// Colors a category can be given (Settings → Categories).
  static const List<Color> categoryChoices = [
    Color(0xFF2196F3), // blue
    Color(0xFFF44336), // red
    Color(0xFF4CAF50), // green
    Color(0xFFF9A825), // yellow
    Color(0xFF9C27B0), // purple
    Color(0xFFFF9800), // orange
    Color(0xFF009688), // teal
    Color(0xFFE91E63), // pink
    Color(0xFF3F51B5), // indigo
    Color(0xFF795548), // brown
  ];

  /// Pie chart slice colors, used in order.
  static const List<Color> chart = [
    Colors.blue,
    Colors.red,
    Colors.green,
    star,
    Colors.purple,
    Colors.orange,
  ];
}

/// Spacing and corner radii, so every page lines up the same way.
class AppSpacing {
  AppSpacing._();

  static const double page = 25; // left/right margin of every page
  static const double section = 15; // vertical gap between form rows
  static const double gap = 10; // horizontal gap between side-by-side boxes
  static const double boxRadius = 35; // input boxes and big buttons
  static const double cardRadius = 15; // list cards and small fields
}

/// Named text styles. They don't set a font family: Text widgets inherit
/// Nunito from the theme (see [buildAppTheme]).
class AppText {
  AppText._();

  static const String fontFamily = 'Nunito';

  static const TextStyle hero = TextStyle(fontSize: 35, fontWeight: FontWeight.bold);
  static const TextStyle amount = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const TextStyle headline = TextStyle(fontSize: 25, fontWeight: FontWeight.bold);
  static const TextStyle title = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  static const TextStyle strong = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  static const TextStyle body = TextStyle(fontSize: 16);
  static const TextStyle bodyMuted = TextStyle(fontSize: 16, color: AppColors.muted);
  static const TextStyle label = TextStyle(fontSize: 14, color: AppColors.muted);
  static const TextStyle caption = TextStyle(fontSize: 12, color: AppColors.muted);
}

ThemeData buildAppTheme() {
  return ThemeData(
    fontFamily: AppText.fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.background,
    // Plain Text() widgets use bodyMedium; keep it at 16 like the old customText default.
    textTheme: const TextTheme(bodyMedium: AppText.body),
  );
}
