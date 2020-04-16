import 'dart:ui';
import 'package:flutter/material.dart';

extension CustomColorScheme on ColorScheme {
  static Color insert = Color(0xff00ABFF);
  static Color edit = Colors.amber;
  static Color createWidget = Colors.lightGreen;

  // TODO review
  Color get defaultTextColor =>
      this.brightness == Brightness.light ? Colors.black : Colors.white;
  Color get negativeDefaultTxtColor =>
      this.brightness == Brightness.light ? Colors.white : Colors.black;
  Color get auto => this.brightness == Brightness.light
      ? Colors.blueGrey
      : const Color(0xff517975);
  Color get navigationBlue => insert;

  /// Actions Dropdown
  Color get actionsDropdownBg => this.brightness == Brightness.light
      ? Colors.grey[700]
      : Colors.black87; // Colors.grey[400]
  Color get actionsDropdownTextColor =>
      this.brightness == Brightness.light ? Colors.white : Colors.black;
  Color get insertTextColor =>
      this.brightness == Brightness.light ? null : insert;
  Color get editTextColor => this.brightness == Brightness.light ? null : edit;
  Color get createWidgetTextColor =>
      this.brightness == Brightness.light ? null : createWidget;
  Color get insertBgColor =>
      this.brightness == Brightness.light ? insert : null;
  Color get editBgColor => this.brightness == Brightness.light ? edit : null;
  Color get createWidgetBgColor =>
      this.brightness == Brightness.light ? createWidget : null;

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
    brightness: Brightness.light,
    colorScheme: ColorScheme.light().copyWith(
        primary: Colors.white
    ),
    inputDecorationTheme: InputDecorationTheme(
        focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent, width: 2))),
  );

  static ThemeData darkTheme = ThemeData(
      primaryColor: Colors.grey[850],
      canvasColor: Colors.grey[900],
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark().copyWith(
          primary: Colors.grey[850]
      ),
      accentColor: Colors.blue,
      inputDecorationTheme: InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent, width: 2))));
}
