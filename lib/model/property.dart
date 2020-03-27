import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:postgres/postgres.dart';

class Property<T> extends Equatable {
  final int index;
  final String name;
  final PostgreSQLDataType type;
  final T columnDefault;
  final bool isNullable;
  final int charMaxLength;

  Property(this.index, this.name, this.type, this.columnDefault, this.isNullable, this.charMaxLength);

  @override
  List<Object> get props => [name, type];

  @override
  String toString() {
    return "\n$name ($type, columnDefault: $columnDefault, isNullable: $isNullable, charMaxLength: $charMaxLength)";
  }
}