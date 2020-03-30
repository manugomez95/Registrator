import 'dart:ui';

import 'package:bitacora/conf/colors.dart' as app;
import 'package:flutter/material.dart';
import 'package:recase/recase.dart';

enum ActionType { InsertInto, EditLastFrom, CreateWidgetFrom }

final actions = <Action>[
  Action(ActionType.InsertInto, app.Colors.insert, Colors.white),
  Action(ActionType.EditLastFrom, app.Colors.edit, Colors.white),
  Action(ActionType.CreateWidgetFrom, app.Colors.createWidget, Colors.white),
];

class Action {
  const Action._(this.title, this.type, this.primaryColor, this.textColor);

  factory Action (type, primaryColor, textColor) {
    final title = ReCase(type.toString().split(".").last)
        .sentenceCase
        .toUpperCase();
    return Action._(title, type, primaryColor, textColor);
  }

  final String title;
  final ActionType type;
  final Color primaryColor;
  final Color textColor;
}
