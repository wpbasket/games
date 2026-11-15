import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../engine/ludo_models.dart';

class LudoColors {
  // Edge-to-edge system UI style for light background:
  // Both top status bar icons and bottom navigation bar buttons are dark/black
  static const SystemUiOverlayStyle systemUiStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  // Red Palette
  static const Color red = Color(0xFFE53935);
  static const Color redLight = Color(0xFFFFEBEE);
  static const Color redDark = Color(0xFFC62828);

  // Green Palette
  static const Color green = Color(0xFF43A047);
  static const Color greenLight = Color(0xFFE8F5E9);
  static const Color greenDark = Color(0xFF2E7D32);

  // Yellow Palette
  static const Color yellow = Color(0xFFFDD835);
  static const Color yellowLight = Color(0xFFFFFDE7);
  static const Color yellowDark = Color(0xFFF57F17);

  // Blue Palette
  static const Color blue = Color(0xFF1E88E5);
  static const Color blueLight = Color(0xFFE3F2FD);
  static const Color blueDark = Color(0xFF1565C0);

  // Board Neutrals
  static const Color boardBackground = Color(0xFFFFFFFF);
  static const Color boardGridLine = Color(0xFFE0E0E0);
  static const Color boardDarkGrid = Color(0xFFBDBDBD);
  static const Color starGold = Color(0xFFFFB300);

  // App Theme
  static const Color surfaceDark = Color(0xFF1E1E2C);
  static const Color backgroundDark = Color(0xFF12121E);
  static const Color accentGold = Color(0xFFFFC107);

  static Color primary(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        return red;
      case PlayerColor.green:
        return green;
      case PlayerColor.yellow:
        return yellow;
      case PlayerColor.blue:
        return blue;
    }
  }

  static Color light(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        return redLight;
      case PlayerColor.green:
        return greenLight;
      case PlayerColor.yellow:
        return yellowLight;
      case PlayerColor.blue:
        return blueLight;
    }
  }

  static Color dark(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        return redDark;
      case PlayerColor.green:
        return greenDark;
      case PlayerColor.yellow:
        return yellowDark;
      case PlayerColor.blue:
        return blueDark;
    }
  }
}
