import 'package:bitacora/model/table.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:equatable/equatable.dart';

// ignore: must_be_immutable
class Property<T> extends Equatable {
  final int dbPosition;
  final String name;
  final DataType type;
  final T columnDefault;
  final bool isNullable;
  final int charMaxLength;
  T lastValue; /// do save for when you don't want an ordered table
  Table foreignKeyOf;

  Property(this.dbPosition, this.name, this.type, this.columnDefault,
      this.isNullable, {this.charMaxLength});

  @override
  String toString() {
    return "\n$name ($type, columnDefault: $columnDefault, isNullable: $isNullable, charMaxLength: $charMaxLength, foreignKeyOf: $foreignKeyOf)";
  }

  @override
  List<Object> get props => [name, type];
}
