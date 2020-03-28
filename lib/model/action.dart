import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:recase/recase.dart';

enum ActionType { InsertInto, EditLastFrom, CreateWidgetFrom }

final actions = <Action>[
  Action(ActionType.InsertInto, Colors.blue, Colors.white),
  Action(ActionType.EditLastFrom, Colors.orangeAccent, Colors.white),
  Action(ActionType.CreateWidgetFrom, Colors.green, Colors.white),
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
