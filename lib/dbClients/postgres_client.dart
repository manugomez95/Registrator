import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:postgres/postgres.dart';
import 'package:registrator/model/databaseModel.dart';
import 'package:registrator/model/property.dart';
import 'package:registrator/model/table.dart' as my;

// TODO complete and add short name field and flutter input type
var postgresTypes = {
  "timestamp without time zone": PostgreSQLDataType.timestampWithoutTimezone,
  "timestamp with time zone": PostgreSQLDataType.timestampWithTimezone,
  "character varying": PostgreSQLDataType.text,
  "integer": PostgreSQLDataType.integer,
  "smallint": PostgreSQLDataType.smallInteger,
  "boolean": PostgreSQLDataType.boolean,
  "real": PostgreSQLDataType.real,
  "date": PostgreSQLDataType.date,
  "oid": PostgreSQLDataType.uuid
};

class PostgresClient {
  var _connection;

  /// Private constructor
  PostgresClient._create() {
    print("_create() (private constructor)");

    // Do most of your initialization here, that's what a constructor is for
    //...
  }

  /// Public factory
  static Future<PostgresClient> create() async {
    print("create() (public factory)");

    // Call the private constructor
    var component = PostgresClient._create();
    component._connection = new PostgreSQLConnection(
        "192.168.1.14", 5432, "my_data",
        username: "postgres", password: r"!$36<BD5vuP7");
    await component._connection.open();
    // Do initialization that requires async
    //await component._complexAsyncInit();

    // Return the fully initialized object
    return component;
  }

  Future<List<String>> getTables() async {
    List<List<dynamic>> results = await _connection.query(
        r"SELECT table_name "
        r"FROM information_schema.tables "
        r"WHERE table_type = 'BASE TABLE' "
        r"AND table_schema = @tableSchema",
        substitutionValues: {"tableSchema": "public"});

    return results.expand((i) => i).toList().cast<String>();
  }

  Future<List<Property>> getPropertiesFromTable(String table) async {
    List<List<dynamic>> results = await _connection.query(
        r"SELECT ordinal_position, column_name, data_type, column_default, is_nullable, character_maximum_length FROM information_schema.columns "
        r"WHERE table_schema = @tableSchema AND table_name   = @tableName",
        substitutionValues: {"tableSchema": "public", "tableName": table});

    var r = results
        .map((res) {
          return Property(res[0] - 1, res[1], postgresTypes[res[2]], res[3],
              res[4] == 'YES' ? true : false, res[5]);
        })
        .toList()
        .cast<Property>();

    debugPrint(r.toString());

    return r;
  }

  Future<bool> insertRowIntoTable(
      String table, Map<String, String> propertiesForm) async {
    String properties = propertiesForm.keys
        .map((e) => e.toLowerCase() == e ? e : "\"$e\"")
        .join(", ");
    String values =
        propertiesForm.keys.map((k) => propertiesForm[k]).join(", ");
    print("INSERT INTO $table ($properties) VALUES ($values)");

    try {
      var results = await _connection
          .execute("INSERT INTO $table ($properties) VALUES ($values)");
      print(results);
      if (results == 1)
        return Future.value(true);
      else
        return Future.value(false);
    } on PostgreSQLException catch (e) {
      print(e);
      throw e;
    }
  }

  Future<DatabaseModel> getDatabaseModel(dbName) async {
    List<List<dynamic>> tablesResponse = await _connection.query(
        r"SELECT table_name "
        r"FROM information_schema.tables "
        r"WHERE table_type = 'BASE TABLE' "
        r"AND table_schema = @tableSchema",
        substitutionValues: {"tableSchema": "public"});

    List<String> tablesNames =
        tablesResponse.expand((i) => i).toList().cast<String>();

    print(tablesNames);

    List<my.Table> tables = [];
    for (var tName in tablesNames) {
      List<Property> properties = await getPropertiesFromTable(tName);
      tables.add(my.Table(tName, properties));
    }

    print(tables);

    return DatabaseModel(dbName, tables);
  }

  void close() {
    _connection.close();
  }
}
