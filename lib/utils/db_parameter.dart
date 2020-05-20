import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:simple_rsa/simple_rsa.dart';

abstract class PropertyType<T> {
  T value;
}

/// Defines the parameters of a connection with a DB
class DbConnectionParams extends Equatable{
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

enum PrimitiveType {
  text,
  varchar,
  integer,
  smallInt,
  bigInt,
  real,
  boolean,
  timestamp,
  time,
  date,
  byteArray
}

class DbInfo {
  final Widget _logoLight;
  final Widget _logoDark;
  final String alias;
  final String id;
  //final DbConnectionParams connectionParams;

  SvgPicture getLogo(Brightness brightness) => brightness == Brightness.light ? this._logoLight : this._logoDark;

  const DbInfo._(this.alias, this.id, this._logoLight, this._logoDark);

  factory DbInfo (String id) {
    switch(id) {
      case "postgres":
        var logoLight = SvgPicture.asset('assets/images/postgresql_elephant.svg',
            height: 75, semanticsLabel: 'Postgres Logo');
        return DbInfo._("PostgreSQL", id, logoLight, logoLight);
        break;
      case "sqlite_android":
        var logoLight = SvgPicture.asset('assets/images/SQLite.svg',
            height: 55, semanticsLabel: 'SQLite Logo');

        var logoDark = SvgPicture.asset('assets/images/SQLite_dark.svg',
            height: 55, semanticsLabel: 'SQLite Logo');
        return DbInfo._("SQLite", id, logoLight, logoDark);
        break;
      case "bigquery":
        var logoLight = SvgPicture.asset('assets/images/BigQuery.svg',
            height: 75, semanticsLabel: 'BigQuery Logo');
        return DbInfo._("BigQuery", id, logoLight, logoLight);
        break;
      default:
        throw Exception("Db not supported");
    }
  }
}

// TODO instead of string enum Databases.Postgres?
List<DbInfo> supportedDatabases = [DbInfo("postgres")];

extension PrimitiveTypeExtension on PrimitiveType {

  dynamic get defaultV {
    switch (this) {
      case PrimitiveType.boolean:
        return null;
      case PrimitiveType.timestamp:
      case PrimitiveType.time:
      case PrimitiveType.date:
        return DateTime.now();
      default:
        return '';
    }
  }
}

class DataType extends Equatable {
  final PrimitiveType primitive;
  final alias;
  final isArray;

  const DataType(this.primitive, this.alias, {this.isArray: false});

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

