import 'package:equatable/equatable.dart';
import 'package:postgres/postgres.dart';
import 'package:simple_rsa/simple_rsa.dart';

abstract class PropertyType<T> {
  T value;
}

/// Defines the parameters of a connection with a DB
abstract class DbConnectionParams extends Equatable{
  final String alias;
  final String host;
  final int port;
  final String dbName;
  final String username;
  final String password;
  final bool useSSL;

  final PUBLIC_KEY =
      "MIIBITANBgkqhkiG9w0BAQEFAAOCAQ4AMIIBCQKCAQBuAGGBgg9nuf6D2c5AIHc8" +
          "vZ6KoVwd0imeFVYbpMdgv4yYi5obtB/VYqLryLsucZLFeko+q1fi871ZzGjFtYXY" +
          "9Hh1Q5e10E5hwN1Tx6nIlIztrh5S9uV4uzAR47k2nng7hh6vuZ33kak2hY940RSL" +
          "H5l9E5cKoUXuQNtrIKTS4kPZ5IOUSxZ5xfWBXWoldhe+Nk7VIxxL97Tk0BjM0fJ3" +
          "8rBwv3++eAZxwZoLNmHx9wF92XKG+26I+gVGKKagyToU/xEjIqlpuZ90zesYdjV+" +
          "u0iQjowgbzt3ASOnvJSpJu/oJ6XrWR3egPoTSx+HyX1dKv9+q7uLl6pXqGVVNs+/" +
          "AgMBAAE=";

  Future<Map<String, dynamic>> toMap() async {
    return {
      'alias': alias,
      'host': host,
      'port': port,
      'db_name': dbName,
      'username': username,
      'password': await encryptString(password, PUBLIC_KEY),
      'ssl': useSSL ? 1 : 0,
    };
  }

  DbConnectionParams(this.alias, this.host, this.port, this.dbName, this.username, this.password, this.useSSL);

  List<Object> get props => [this.alias, this.host, this.port, this.dbName, this.username, this.password, this.useSSL];
}

class PgConnectionParams extends DbConnectionParams {
  PgConnectionParams(String alias, String host, int port, String dbName, String username, String password, bool useSSL) : super(alias, host, port, dbName, username, password, useSSL);
}

enum PrimitiveType {
  text,
  varchar,
  integer,
  smallInt,
  bigInt,
  real,
  boolean,
  timestamp,
  date,
  byteArray
}

class DataType extends Equatable {
  final PrimitiveType primitive;
  final alias;
  final isArray;

  const DataType(this.primitive, this.alias, this.isArray);

  @override
  String toString() {
    return alias;
  }

  @override
  List<Object> get props => [primitive, alias, isArray];
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

