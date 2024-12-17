import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';

abstract class PropertyType<T> {
  late T value;
}

/// Defines the parameters of a connection with a DB
class DbConnectionParams extends Equatable {
  final String alias;
  final String host;
  final int port;
  final String dbName;
  final String username;
  final String password;
  final bool useSSL;
  final String brand;

  static const String _publicKeyPem = '''
-----BEGIN PUBLIC KEY-----
MIIBITANBgkqhkiG9w0BAQEFAAOCAQ4AMIIBCQKCAQBuAGGBgg9nuf6D2c5AIHc8
vZ6KoVwd0imeFVYbpMdgv4yYi5obtB/VYqLryLsucZLFeko+q1fi871ZzGjFtYXY
9Hh1Q5e10E5hwN1Tx6nIlIztrh5S9uV4uzAR47k2nng7hh6vuZ33kak2hY940RSL
H5l9E5cKoUXuQNtrIKTS4kPZ5IOUSxZ5xfWBXWoldhe+Nk7VIxxL97Tk0BjM0fJ3
8rBwv3++eAZxwZoLNmHx9wF92XKG+26I+gVGKKagyToU/xEjIqlpuZ90zesYdjV+
u0iQjowgbzt3ASOnvJSpJu/oJ6XrWR3egPoTSx+HyX1dKv9+q7uLl6pXqGVVNs+/
AgMBAAE=
-----END PUBLIC KEY-----''';

  Future<Map<String, dynamic>> toMap() async {
    final parser = RSAKeyParser();
    final publicKey = parser.parse(_publicKeyPem) as RSAPublicKey;
    final encrypter = Encrypter(RSA(publicKey: publicKey));
    
    return {
      'alias': alias,
      'host': host,
      'port': port,
      'db_name': dbName,
      'username': username,
      'password': encrypter.encrypt(password).base64,
      'ssl': useSSL ? 1 : 0,
      'brand': brand,
    };
  }

  const DbConnectionParams(
    this.alias,
    this.host,
    this.port,
    this.dbName,
    this.username,
    this.password,
    this.useSSL,
    this.brand,
  );

  @override
  List<Object> get props => [
        alias,
        host,
        port,
        dbName,
        username,
        password,
        useSSL,
        brand,
      ];
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
  byteArray,
}

class DbInfo {
  final Widget _logoLight;
  final Widget _logoDark;
  final String alias;
  final String id;

  SvgPicture getLogo(Brightness brightness) {
    return brightness == Brightness.light ? _logoLight as SvgPicture : _logoDark as SvgPicture;
  }

  const DbInfo._(this.alias, this.id, this._logoLight, this._logoDark);

  factory DbInfo(String id) {
    switch (id) {
      case "postgres":
        final logoLight = SvgPicture.asset(
          'assets/images/postgresql_elephant.svg',
          height: 75,
          semanticsLabel: 'Postgres Logo',
        );
        return DbInfo._("PostgreSQL", id, logoLight, logoLight);
      case "sqlite_android":
        final logoLight = SvgPicture.asset(
          'assets/images/SQLite.svg',
          height: 55,
          semanticsLabel: 'SQLite Logo',
        );
        final logoDark = SvgPicture.asset(
          'assets/images/SQLite_dark.svg',
          height: 55,
          semanticsLabel: 'SQLite Logo',
        );
        return DbInfo._("SQLite", id, logoLight, logoDark);
      case "bigquery":
        final logoLight = SvgPicture.asset(
          'assets/images/BigQuery.svg',
          height: 75,
          semanticsLabel: 'BigQuery Logo',
        );
        return DbInfo._("BigQuery", id, logoLight, logoLight);
      default:
        throw Exception("Database not supported");
    }
  }
}

final List<DbInfo> supportedDatabases = [DbInfo("postgres")];

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
  final String alias;
  final bool isArray;

  const DataType(
    this.primitive,
    this.alias, {
    this.isArray = false,
  });

  String get name => isArray ? '$alias[]' : alias;

  @override
  String toString() => name;

  @override
  List<Object> get props => [primitive, alias, isArray];
}

abstract class DbParameter<T> {
  abstract final String title;
  late T value;
  abstract final T defaultValue;
}

class Alias extends DbParameter<String> {
  @override
  final String title = "Alias";
  @override
  final String defaultValue = "My data";
}

class Host extends DbParameter<String> {
  @override
  final String title = "Host";
  @override
  final String defaultValue = "192.168.X.XX";
}

class Port extends DbParameter<int> {
  @override
  final String title = "Port";
  @override
  final int defaultValue = 5432;
}

class DatabaseName extends DbParameter<String> {
  @override
  final String title = "DB name";
  @override
  final String defaultValue = "postgres";
}

class Username extends DbParameter<String> {
  @override
  final String title = "Username";
  @override
  final String defaultValue = "postgres";
}

class Password extends DbParameter<String> {
  @override
  final String title = "Password";
  @override
  final String defaultValue = "Ultra secret";
}

