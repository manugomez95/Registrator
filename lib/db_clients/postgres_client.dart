import 'package:bitacora/bloc/database_model/bloc.dart';
import 'package:bitacora/bloc/database_model/db_model_bloc.dart';
import 'package:bitacora/main.dart';
import 'package:bitacora/model/property.dart';
import 'package:flutter/cupertino.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:postgres/postgres.dart';
import 'package:bitacora/utils/db_parameter.dart';

// TODO change to some other class that implements PostgresClient/RelationalDBClient interface
class PostgresClient {
  String name; // TODO same as db alias???
  PostgreSQLConnection connection;
  List<app.Table> tables;

  /// Private constructor
  PostgresClient._create(String name) {
    this.name = name;
  }

  /// Public factory
  // TODO protect password (encrypt)
  static void create(Database db) async {
    // Call the private constructor
    PostgresClient component = PostgresClient._create(db.alias);
    component.connection = PostgreSQLConnection(db.host, db.port, db.dbName,
        username: db.username, password: db.password, useSSL: db.useSSL);
    try {
      await component.connection.open();
      await component.getDatabaseModel();
      getIt<DatabaseModelBloc>().add(ConnectionSuccessfulEvent(component));
    } on Exception catch (e) {
      getIt<DatabaseModelBloc>().add(ConnectionErrorEvent(component, e));
    }
  }

  Future<void> updateStatus() async {
    if (connection.isClosed) {
      print(await connection.open());
    }
  }

  Future<List<String>> getTables({verbose: false}) async {
    try {
      List<List<dynamic>> tablesResponse = await connection.query(
          r"SELECT table_name "
          r"FROM information_schema.tables "
          r"WHERE table_type = 'BASE TABLE' "
          r"AND table_schema = @tableSchema",
          substitutionValues: {"tableSchema": "public"});

      List<String> tablesNames =
          tablesResponse.expand((i) => i).toList().cast<String>();

      if (verbose) debugPrint(tablesNames.toString());
      return tablesNames;
    } on PostgreSQLException catch (e) {
      debugPrint(e.toString());
      throw e;
    }
  }

  Future<List<Property>> getPropertiesFromTable(String table, {verbose: false}) async {
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
                PostgresDataType(res[2], udtName: res[6]),
                res[3],
                res[4] == 'YES' ? true : false,
                res[5]);
          })
          .toList()
          .cast<Property>();

      if (verbose) debugPrint(r.toString());

      return r;
    } on PostgreSQLException catch (e) {
      debugPrint(e.toString());
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

  Future<bool> updateLastRow(
      app.Table table, Map<String, String> propertiesForm) async {
    String properties = propertiesForm.keys
        .map((e) => e.toLowerCase() == e ? e : "\"$e\"")
        .join(", ");
    String values =
    propertiesForm.keys.map((k) => propertiesForm[k]).join(", ");

    Property linearityProperty = table.properties.firstWhere((p) => p.definesLinearity);
    String last =
        "SELECT ctid FROM ${table.name} ORDER BY ${linearityProperty.name.toLowerCase() == linearityProperty.name ? linearityProperty.name : "\"${linearityProperty.name}\""} DESC LIMIT 1";

    String sql = "UPDATE ${table.name} SET ($properties) = ($values) WHERE ctid IN ($last)";
    debugPrint(sql);
    try {
      var results = await connection.execute(sql);
      debugPrint("updateLastRow: $results");
      if (results == 1)
        return Future.value(true);
      else
        return Future.value(false);
    } on PostgreSQLException catch (e) {
      print(e);
      throw e;
    }
  }

  void getLastRow(app.Table table, {verbose: false}) async {
    Property linearityProperty = table.properties.firstWhere((p) => p.definesLinearity, orElse: () => null);
    if (linearityProperty == null) {
      if (verbose) debugPrint("getLastRow: No linearity defined for ${table.name}");
      return;
    }
    String sql =
        "SELECT * FROM ${table.name} ORDER BY ${linearityProperty.name.toLowerCase() == linearityProperty.name ? linearityProperty.name : "\"${linearityProperty.name}\""} DESC LIMIT 1";
    if (verbose) debugPrint("getLastRow: $sql");
    try {
      List<List<dynamic>> results = await connection.query(sql);
      if (verbose) debugPrint("getLastRow: $results");

      table.properties.asMap().forEach((index, p) => p.lastValue = results[0][index]); // TODO format accordingly to type / fix postgres plugin bug where array is retrieved badly

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
    debugPrint("cancelLastInsertion: $sql");
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

  Future<List<app.Table>> getDatabaseModel({verbose: false}) async {
    if (verbose) {
      debugPrint("_________________");
      if (this.tables != null) debugPrint("getDatabaseModel: Updating model");
      else debugPrint("getDatabaseModel: Getting model for the first time");
    }

    /// Get tables
    List<String> tablesNames = await getTables(verbose: verbose);

    /// For each table:
    List<app.Table> tables = [];
    for (var tName in tablesNames) {
      /// get properties...
      List<Property> properties = await getPropertiesFromTable(tName);

      /// identify the "timeline field"...
      Property linearity;
      for (final p in properties) {
        if ([PostgreSQLDataType.date, PostgreSQLDataType.timestampWithTimezone, PostgreSQLDataType.timestampWithoutTimezone].contains(p.type.complete))
          if (linearity == null) linearity = p;
          else {
            linearity = null;
            break;
          }
      }
      if (linearity != null) linearity.definesLinearity = true;
      tables.add(app.Table(tName, properties, this));

      /// and get last row
      getLastRow(tables.last);
    }

    this.tables = tables;

    if (verbose) debugPrint("getDatabaseModel: ${tables.toString()}");
    if (verbose) debugPrint("_________________");
    return tables;
  }
}
