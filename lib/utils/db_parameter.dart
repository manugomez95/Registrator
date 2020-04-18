import 'package:equatable/equatable.dart';
import 'package:postgres/postgres.dart';

abstract class PropertyType<T> {
  T value;
}

// TODO doesnt need to be a class, could be a List<DbParams>
abstract class DbDescription extends Equatable{
  final String alias;
  final String host;
  final int port;
  final String dbName;
  final String username;
  final String password;
  final bool useSSL;

  DbDescription(this.alias, this.host, this.port, this.dbName, this.username, this.password, this.useSSL);

  List<Object> get props => [this.alias, this.host, this.port, this.dbName, this.username, this.password, this.useSSL];
}

class PostgreSQL extends DbDescription {
  PostgreSQL(String alias, String host, int port, String dbName, String username, String password, bool useSSL) : super(alias, host, port, dbName, username, password, useSSL);
}

class PostgresDataType {
  final PostgreSQLDataType complete;
  final alias;
  final isArray;

  const PostgresDataType._(this.complete, this.alias, this.isArray);

  factory PostgresDataType (String dataType, {udtName, isArray: false}) {
    String arrayStr = isArray ? "[ ]" : "";
    switch (dataType) {
      case "timestamp without time zone":
        return PostgresDataType._(PostgreSQLDataType.timestampWithoutTimezone, "timestampWithoutTimezone"+arrayStr, isArray);
      case "timestamp with time zone":
        return PostgresDataType._(PostgreSQLDataType.timestampWithTimezone, "timestampWithTimezone"+arrayStr, isArray);
      case "character varying":
      case "text":
      case "_text":
        return PostgresDataType._(PostgreSQLDataType.text, "text"+arrayStr, isArray);
      case "integer":
        return PostgresDataType._(PostgreSQLDataType.integer, "integer"+arrayStr, isArray);
      case "smallint":
        return PostgresDataType._(PostgreSQLDataType.smallInteger, "smallInteger"+arrayStr, isArray);
      case "boolean":
        return PostgresDataType._(PostgreSQLDataType.boolean, "boolean"+arrayStr, isArray);
      case "real":
        return PostgresDataType._(PostgreSQLDataType.real, "real"+arrayStr, isArray);
      case "date":
        return PostgresDataType._(PostgreSQLDataType.date, "date"+arrayStr, isArray);
      case "oid":
        return PostgresDataType._(PostgreSQLDataType.uuid, "uuid"+arrayStr, isArray);
      case "ARRAY":
        return PostgresDataType(udtName, isArray: true);
      default:
        throw UnsupportedError("$dataType not supported as a type");
    }
  }

  @override
  String toString() {
    return alias;
  }
}

abstract class DbParameter<T> {
  String title;
  T value;
  T defaultValue;
}

class Alias extends DbParameter<String> {
  @override
  String get title => "Alias";
  @override
  String get defaultValue => "My data";
}

class Host extends DbParameter<String> {
  @override
  String get title => "Host";
  @override
  String get defaultValue => "192.168.X.XX";
}

class Port extends DbParameter<int> {
  @override
  String get title => "Port";
  @override
  int get defaultValue => 5432;
}

class DatabaseName extends DbParameter<String> {
  @override
  String get title => "DB name";
  @override
  String get defaultValue => "postgres";
}

class Username extends DbParameter<String> {
  @override
  String get title => "Username";
  @override
  String get defaultValue => "postgres";
}

class Password extends DbParameter<String> {
  @override
  String get title => "Password";
  @override
  String get defaultValue => "Ultra secret";
}

