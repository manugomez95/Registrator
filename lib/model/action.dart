import 'package:flutter/material.dart';

enum ActionType {
  insertInto,
  editLastFrom,
  deleteLastFrom,
}

class Action {
  final ActionType type;
  final String title;
  final String name;
  final IconData icon;
  final Color color;

  const Action(this.type, this.name, this.icon, this.color) : title = name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Action &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          name == other.name;

  @override
  int get hashCode => type.hashCode ^ name.hashCode;
}
