import 'package:bitacora/utils/db_parameter.dart';

class Property<T> {
  final int index;
  final String name;
  final PostgresDataType type;
  final T columnDefault;
  final bool isNullable;
  final int charMaxLength;
  bool definesLinearity;
  T lastValue;

  Property(this.index, this.name, this.type, this.columnDefault, this.isNullable, this.charMaxLength, {this.definesLinearity: false});

  @override
  String toString() {
    return "\n$name ($type, columnDefault: $columnDefault, isNullable: $isNullable, charMaxLength: $charMaxLength, definesLinearity: $definesLinearity)";
  }
}
