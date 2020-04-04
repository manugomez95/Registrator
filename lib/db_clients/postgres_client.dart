import 'package:bitacora/model/property.dart';
import 'package:flutter/cupertino.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:postgres/postgres.dart';

// TODO complete and add short name field and flutter input type
PostgreSQLDataType standardizeType(String dataType, {udtName}) {
  switch (dataType) {
    case "timestamp without time zone":
      return PostgreSQLDataType.timestampWithoutTimezone;
    case "timestamp with time zone":
      return PostgreSQLDataType.timestampWithTimezone;
    case "character varying":
    case "text":
    case "_text":
      return PostgreSQLDataType.text;
    case "integer":
      return PostgreSQLDataType.integer;
    case "smallint":
      return PostgreSQLDataType.smallInteger;
    case "boolean":
      return PostgreSQLDataType.boolean;
    case "real":
      return PostgreSQLDataType.real;
    case "date":
      return PostgreSQLDataType.date;
    case "oid":
      return PostgreSQLDataType.uuid;
    case "ARRAY":
      return standardizeType(udtName);
    default:
      throw Exception; // TODO define Exceptions
  }
}

// TODO change to some other class that implements PostgresClient/RelationalDBClient interface
class PostgresClient {
  String name;
  PostgreSQLConnection connection;
  List<app.Table> tables;

  /// Private constructor
  PostgresClient._create(String name) {
    print("_create() (private constructor)");
    this.name = name;
    // Do most of your initialization here, that's what a constructor is for
    //...
  }

  /// Public factory
  // TODO protect password (encrypt)
  static Future<PostgresClient> create(String name,
      String host, int port, String database, bool useSSL,
      {String username, String password}) async {
    print("create() (public factory)");

    // Call the private constructor
    PostgresClient component = PostgresClient._create(name);
    component.connection = PostgreSQLConnection(host, port, database,
        username: username, password: password, useSSL: useSSL);
    try {
      await component.connection.open();
      // Do initialization that requires async
      //await component._complexAsyncInit();

      // Return the fully initialized object
      return component;
    } on Exception catch (e) {
      print(e);
      throw e;
    }
  }

  Future<List<String>> getTables() async {
    try {
      List<List<dynamic>> tablesResponse = await connection.query(
          r"SELECT table_name "
          r"FROM information_schema.tables "
          r"WHERE table_type = 'BASE TABLE' "
          r"AND table_schema = @tableSchema",
          substitutionValues: {"tableSchema": "public"});

      List<String> tablesNames =
          tablesResponse.expand((i) => i).toList().cast<String>();

      print(tablesNames);
      return tablesNames;
    } on PostgreSQLException catch (e) {
      print(e);
      throw e;
    }
  }

  Future<List<Property>> getPropertiesFromTable(String table) async {
    try {
      List<List<dynamic>> results = await connection.query(
          r"SELECT ordinal_position, column_name, data_type, column_default, is_nullable, character_maximum_length, udt_name FROM information_schema.columns "
          r"WHERE table_schema = @tableSchema AND table_name   = @tableName",
          substitutionValues: {"tableSchema": "public", "tableName": table});

      var r = results
          .map((res) {
            return Property(
                res[0] - 1,
                res[1],
                standardizeType(res[2], udtName: res[6]),
                res[3],
                res[4] == 'YES' ? true : false,
                res[5],
                res[2] == 'ARRAY' ? true : false);
          })
          .toList()
          .cast<Property>();

      debugPrint(r.toString());

      return r;
    } on PostgreSQLException catch (e) {
      print(e);
      throw e;
    }
  }

  Future<bool> insertRowIntoTable(
      String table, Map<String, String> propertiesForm) async {
    String properties = propertiesForm.keys
        .map((e) => e.toLowerCase() == e ? e : "\"$e\"")
        .join(", ");
    String values =
        propertiesForm.keys.map((k) => propertiesForm[k]).join(", ");

    String sql = "INSERT INTO $table ($properties) VALUES ($values)";
    debugPrint(sql);
    try {
      var results = await connection.execute(sql);
      debugPrint("insertRowIntoTable: $results");
      if (results == 1)
        return Future.value(true);
      else
        return Future.value(false);
    } on PostgreSQLException catch (e) {
      print(e);
      throw e;
    }
  }

  /// Deleting with ctid I don't need a PK
  // TODO awesome printing usefulness, copy where I can
  Future<bool> cancelLastInsertion(
      String table, Map<String, String> propertiesForm) async {
    String whereString = propertiesForm.keys
        .map((e) =>
            "${e.toLowerCase() == e ? e : "\"$e\""} ${propertiesForm[e] == "null" ? "is null" : "= ${propertiesForm[e]}"}")
        .join(" AND ");

    String sql =
        "DELETE FROM $table WHERE ctid IN (SELECT ctid FROM $table WHERE $whereString LIMIT 1)";
    debugPrint(sql);
    try {
      var results = await connection.execute(sql);
      debugPrint("cancelLastInsertion: $results");
      if (results == 1)
        return Future.value(true);
      else
        return Future.value(false);
    } on PostgreSQLException catch (e) {
      print(e);
      throw e;
    }
  }

  Future<List<app.Table>> getDatabaseModel() async {
    if (this.tables != null) return this.tables;

    /// Get tables
    List<String> tablesNames = await getTables();

    /// For each table get properties
    List<app.Table> tables = [];
    for (var tName in tablesNames) {
      List<Property> properties = await getPropertiesFromTable(tName);
      tables.add(app.Table(tName, properties, this));
    }

    this.tables = tables;

    print(tables);
    return tables;
  }
}
