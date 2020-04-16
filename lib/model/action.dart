import 'dart:ui';

import 'package:bitacora/conf/style.dart' as app;
import 'package:bitacora/conf/style.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:recase/recase.dart';

import '../main.dart';
import 'app_data.dart';

enum ActionType { InsertInto, EditLastFrom, CreateWidgetFrom }

class Action extends Equatable {
  const Action._(this.title, this.type, this.bgColor, this.textColor, this.floatButColor);

  factory Action (type, primaryColor, textColor, Brightness brightness) {
    final title = ReCase(type.toString().split(".").last)
        .sentenceCase
        .toUpperCase();
    final floatButColor = brightness == Brightness.light ? primaryColor : textColor;
    return Action._(title, type, primaryColor, textColor, floatButColor);
  }

  final String title;
  final ActionType type;
  final Color bgColor;
  final Color textColor;
  final Color floatButColor;

  @override
  List<Object> get props => [type];
}
