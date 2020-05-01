import 'dart:ui';
import 'package:flutter/material.dart';

extension CustomColorScheme on ColorScheme {
  static Color lightInsert = Colors.blue;
  static Color lightEdit = Colors.amber[700];
  static Color lightCreateWidget = Colors.green;

  static Color darkInsert = Colors.cyanAccent;
  static Color darkEdit = Colors.amberAccent;
  static Color darkCreateWidget = Colors.greenAccent;

  Color get appBarColor =>
      this.brightness == Brightness.light ? Colors.grey[50] : Colors.grey[900];
  Color get defaultTextColor =>
      this.brightness == Brightness.light ? Colors.black : Colors.white;
  Color get negativeDefaultTxtColor =>
      this.brightness == Brightness.light ? Colors.white : Colors.black;
  Color get auto => this.brightness == Brightness.light
      ? Colors.blueGrey
      : const Color(0xff517975);

  /// Actions Dropdown
  Color get actionsDropdownBg => this.brightness == Brightness.light
      ? Colors.grey[700]
      : Colors.black87; // Colors.grey[400]
  Color get actionsDropdownTextColor =>
      this.brightness == Brightness.light ? Colors.white : Colors.black;
  Color get insertTextColor =>
      this.brightness == Brightness.light ? null : darkInsert;
  Color get editTextColor =>
      this.brightness == Brightness.light ? null : darkEdit;
  Color get createWidgetTextColor =>
      this.brightness == Brightness.light ? null : darkCreateWidget;
  Color get insertBgColor =>
      this.brightness == Brightness.light ? lightInsert : null;
  Color get editBgColor =>
      this.brightness == Brightness.light ? lightEdit : null;
  Color get createWidgetBgColor =>
      this.brightness == Brightness.light ? lightCreateWidget : null;

  /// Tables Dropdown
  Color get tablesDropdownBg =>
      this.brightness == Brightness.light ? Colors.grey[350] : Colors.grey[800];
  Color get tablesDropdownTextColor =>
      this.brightness == Brightness.light ? Colors.black : Colors.white;

  /// Property view
  Color get typeBoxColor => this.brightness == Brightness.light
      ? Colors.grey[600]
      : Color(0xff535353);
}

class Themes {
  static ThemeData lightTheme = ThemeData.light();

  static ThemeData darkTheme = ThemeData.dark();
}
