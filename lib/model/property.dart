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
  final bool isArray;

  Property(this.index, this.name, this.type, this.columnDefault, this.isNullable, this.charMaxLength, this.isArray);

  @override
  List<Object> get props => [index, name, type, columnDefault, isNullable, charMaxLength, isArray];

  @override
  String toString() {
    return "\n$name ($type, columnDefault: $columnDefault, isNullable: $isNullable, charMaxLength: $charMaxLength, isArray: $isArray)";
  }
}
