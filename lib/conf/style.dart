import 'dart:ui';
import 'package:flutter/material.dart';

extension CustomColorScheme on ColorScheme {
  static const Color lightInsert = Colors.blue;
  static final Color lightEdit = Colors.amber.shade700;
  static const Color lightCreateWidget = Colors.green;

  static const Color darkInsert = Colors.cyanAccent;
  static const Color darkEdit = Colors.amberAccent;
  static const Color darkCreateWidget = Colors.greenAccent;

  Color get appBarColor =>
      brightness == Brightness.light ? Colors.grey.shade50 : Colors.grey.shade900;
      
  Color get defaultTextColor =>
      brightness == Brightness.light ? Colors.black : Colors.white;
      
  Color get negativeDefaultTxtColor =>
      brightness == Brightness.light ? Colors.white : Colors.black;
      
  Color get auto => brightness == Brightness.light
      ? Colors.blueGrey
      : const Color(0xff517975);

  /// Actions Dropdown
  Color get actionsDropdownBg => brightness == Brightness.light
      ? Colors.grey.shade700
      : Colors.black87;
      
  Color get actionsDropdownTextColor =>
      brightness == Brightness.light ? Colors.white : Colors.black;
      
  Color get insertTextColor =>
      brightness == Brightness.light ? Colors.black : darkInsert;
      
  Color get editTextColor =>
      brightness == Brightness.light ? Colors.black : darkEdit;
      
  Color get createWidgetTextColor =>
      brightness == Brightness.light ? Colors.black : darkCreateWidget;
      
  Color get insertBgColor =>
      brightness == Brightness.light ? lightInsert : Colors.transparent;
      
  Color get editBgColor =>
      brightness == Brightness.light ? lightEdit : Colors.transparent;
      
  Color get createWidgetBgColor =>
      brightness == Brightness.light ? lightCreateWidget : Colors.transparent;

  /// Tables Dropdown
  Color get tablesDropdownBg =>
      brightness == Brightness.light 
          ? Colors.grey.shade300 
          : Colors.grey.shade800;
      
  Color get tablesDropdownTextColor =>
      brightness == Brightness.light ? Colors.black : Colors.white;

  /// Property view
  Color get typeBoxColor => brightness == Brightness.light
      ? Colors.grey.shade600
      : const Color(0xff535353);
}

class Themes {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(),
    useMaterial3: true,
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(),
    useMaterial3: true,
  );
}
