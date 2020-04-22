import 'dart:ui';
import 'package:flutter/material.dart';

extension CustomColorScheme on ColorScheme {
  static Color lightInsert = Colors.blue;
  static Color lightEdit = Colors.amber;
  static Color lightCreateWidget = Colors.green;

  static Color darkInsert = Colors.lightBlueAccent;
  static Color darkEdit = Colors.amberAccent;
  static Color darkCreateWidget = Colors.lightGreen;

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
  static ThemeData lightTheme = ThemeData(
      primaryColor: Colors.white,
      accentColor: Colors.blueAccent,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light()
          .copyWith(primary: Colors.white, secondary: Colors.blueAccent),
      inputDecorationTheme: InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent, width: 2))));

  static ThemeData darkTheme = ThemeData(
    primaryColor: Colors.grey[850],
    accentColor: Colors.lightBlueAccent,
    canvasColor: Colors.grey[900],
    cardColor: Colors.grey[850],
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark()
        .copyWith(primary: Colors.grey[850], secondary: Colors.lightBlueAccent),
  );
}
