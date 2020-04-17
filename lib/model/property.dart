import 'package:bitacora/model/table.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:equatable/equatable.dart';

// ignore: must_be_immutable
class Property<T> extends Equatable {
  final int dbPosition;
  final String name;
  final PostgresDataType type;
  final T columnDefault;
  final bool isNullable;
  final int charMaxLength;
  bool definesLinearity;
  T lastValue;
  List<T> suggestedValues;
  Table foreignKeyOf;

  Property(this.dbPosition, this.name, this.type, this.columnDefault,
      this.isNullable, this.charMaxLength,
      {this.definesLinearity: false});

  @override
  String toString() {
    return "\n$name ($type, columnDefault: $columnDefault, isNullable: $isNullable, charMaxLength: $charMaxLength, definesLinearity: $definesLinearity, suggestedValues: $suggestedValues, foreignKeyOf: $foreignKeyOf)";
  }

  @override
  // TODO: implement props
  List<Object> get props => [name, type];
}
