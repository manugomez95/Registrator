import 'package:flutter/cupertino.dart';
import 'package:postgres/postgres.dart';
import 'package:bitacora/model/database_model.dart';
import 'package:bitacora/model/property.dart';
import 'package:bitacora/model/table.dart' as app;

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

// TODO change to some other class that implements PostgresClient/RelationalDBClient interface
class PostgresClient {
  PostgreSQLConnection connection;
  List<app.Table> tables;

  /// Private constructor
  PostgresClient._create() {
    print("_create() (private constructor)");

    // Do most of your initialization here, that's what a constructor is for
    //...
  }

  /// Public factory
  // TODO protect password (encrypt)
  static Future<PostgresClient> create(String host, int port, String database,
      {String username, String password}) async {
    print("create() (public factory)");

    // Call the private constructor
    PostgresClient component = PostgresClient._create();
    component.connection = PostgreSQLConnection(host, port, database,
        username: username, password: password);
    await component.connection.open();
    // Do initialization that requires async
    //await component._complexAsyncInit();

    // Return the fully initialized object
    return component;
  }

  Future<List<String>> getTables() async {
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
  }

  Future<List<Property>> getPropertiesFromTable(String table) async {
    List<List<dynamic>> results = await connection.query(
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
      var results = await connection
          .execute("INSERT INTO $table ($properties) VALUES ($values)");
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

  // TODO DELETE WITH ctid SO YOU DON'T NEED A PK
  Future<bool> cancelLastInsertion(
      String table, Map<String, String> propertiesForm) async {

    String whereString = propertiesForm.keys
        .map((e) =>
            "${e.toLowerCase() == e ? e : "\"$e\""} = ${propertiesForm[e]}")
        .join(" AND ");

    try {
      var results = await connection.execute(
          "DELETE FROM $table WHERE ctid IN (SELECT ctid FROM $table WHERE $whereString LIMIT 1)");
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

  void close() {
    connection.close();
  }
}
