import 'package:bitacora/bloc/database/bloc.dart' as alt;
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/model/property.dart';
import 'package:flutter/cupertino.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:postgres/postgres.dart';
import 'package:bitacora/utils/db_parameter.dart';

// TODO change to some other class that implements PostgresClient/RelationalDBClient interface
// ignore: must_be_immutable
class PostgresClient extends DbClient<PostgreSQLConnection> {

  PostgresClient(DbDescription params, {Duration timeout: const Duration(seconds: 3), Duration queryTimeout: const Duration(seconds: 2)}) : super(params, timeout: timeout, queryTimeout: queryTimeout) {
    connection = PostgreSQLConnection(params.host, params.port, params.dbName,
        username: params.username, password: params.password, useSSL: params.useSSL, timeoutInSeconds: timeout.inSeconds, queryTimeoutInSeconds: queryTimeout.inSeconds);
    databaseBloc = alt.DatabaseBloc();
  }

  @override
  List<Object> get props => [
    this.params.host,
    this.params.port,
    this.params.dbName,
    this.params.username
  ];

  /// Always call asynchronously
  @override
  Future<bool> connect({verbose: false, fromForm: false}) async {
    if (connection == null) {
      connection = PostgreSQLConnection(params.host, params.port, params.dbName,
          username: params.username,
          password: params.password,
          useSSL: params.useSSL,
          timeoutInSeconds: timeout.inSeconds,
          queryTimeoutInSeconds: queryTimeout.inSeconds);
    }
    try {
      await connection.open(); // TODO Not enough the first time apparently
      if (verbose)
        debugPrint("connect (${this.params.alias}): Connection established");
      await updateDatabaseModel();
      isConnected = true;
      databaseBloc.add(alt.ConnectionSuccessfulEvent(this, fromForm));
      return true;
    } on Exception catch (e) {
      if (verbose) debugPrint("connect (${this.params.alias}): ${e.toString()}");
      await disconnect(); // todo add with all the connection errors?
      databaseBloc.add(alt.ConnectionErrorEvent(this, e));
      return false;
    }
  }

  @override
  disconnect({verbose: false}) async {
    try {
      await connection?.close()?.timeout(timeout);
    } on Exception catch (e) {
      if (verbose) debugPrint("disconnect (${this.params.alias}): $e");
    }
    finally {
      connection = null;
      isConnected = false;
    }
  }

  @override
  Future<bool> ping({verbose: false}) async {
    if (connection == null) return false;
    String sql = "select 1 from information_schema.columns limit 1";
    try {
      await connection.query(sql).timeout(timeout);
      if (verbose) debugPrint("ping (${this.params.alias}): connected");
      //getIt<DatabaseModelBloc>().add(ConnectionSuccessfulEvent(this, false));
      databaseBloc.add(alt.ConnectionSuccessfulEvent(this, false));
    } on Exception catch (e) {
      if (verbose) debugPrint("ping (${this.params.alias}): not connected");
      await disconnect();
      //getIt<DatabaseModelBloc>().add(ConnectionErrorEvent(this, e));
      databaseBloc.add(alt.ConnectionErrorEvent(this, e));
    } finally {
      // ignore: control_flow_in_finally
      return isConnected;
    }
  }

  @override
  Future<List<app.Table>> updateDatabaseModel({verbose: false}) async {
    if (verbose) {
      if (this.tables != null)
        debugPrint("updateDatabaseModel (${this.params.alias}): Updating model");
      else
        debugPrint("updateDatabaseModel (${this.params.alias}): Getting model for the first time");
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
        if ([
          PostgreSQLDataType.date,
          PostgreSQLDataType.timestampWithTimezone,
          PostgreSQLDataType.timestampWithoutTimezone
        ].contains(p.type.complete)) if (linearity == null)
          linearity = p;
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

    if (verbose) debugPrint("updateDatabaseModel: ${tables.toString()}");
    return tables;
  }

  Future<List<String>> getTables({verbose: false}) async {
    try {
      List<List<dynamic>> tablesResponse = await connection.query(
          r"SELECT table_name "
          r"FROM information_schema.tables "
          r"WHERE table_type = 'BASE TABLE' "
          r"AND table_schema = @tableSchema",
          substitutionValues: {"tableSchema": "public"}).timeout(timeout);

      List<String> tablesNames =
          tablesResponse.expand((i) => i).toList().cast<String>();

      if (verbose) debugPrint("getTables (${this.params.alias}): ${tablesNames.toString()}");
      return tablesNames;
    } on PostgreSQLException catch (e) {
      debugPrint(e.toString());
      throw e;
    }
  }

  @override
  Future<List<Property>> getPropertiesFromTable(String table,
      {verbose: false}) async {
    try {
      List<List<dynamic>> results = await connection.query(
          r"SELECT ordinal_position, column_name, data_type, column_default, is_nullable, character_maximum_length, udt_name FROM information_schema.columns "
          r"WHERE table_schema = @tableSchema AND table_name   = @tableName",
          substitutionValues: {"tableSchema": "public", "tableName": table}).timeout(timeout);

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

  @override
  Future<bool> insertRowIntoTable(
      app.Table table, Map<String, String> propertiesForm,
      {verbose: false}) async {
    String properties = propertiesForm.keys
        .map((e) => e.toLowerCase() == e ? e : "\"$e\"")
        .join(", ");
    String values =
        propertiesForm.keys.map((k) => propertiesForm[k]).join(", ");

    String sql =
        "INSERT INTO ${table.toString()} ($properties) VALUES ($values)";
    debugPrint(sql);
    try {
      var results = await connection.execute(sql).timeout(timeout);
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
      app.Table table, Map<String, String> propertiesForm,
      {verbose: false}) async {
    String properties = propertiesForm.keys
        .map((e) => e.toLowerCase() == e ? e : "\"$e\"")
        .join(", ");
    String values =
        propertiesForm.keys.map((k) => propertiesForm[k]).join(", ");

    Property linearityProperty = table.properties
        .firstWhere((p) => p.definesLinearity, orElse: () => null);
    if (linearityProperty == null) {
      if (verbose)
        debugPrint("updateLastRow (${table.name}): No linearity defined");
      return false;
    }
    String last =
        "SELECT ctid FROM ${table.name} ORDER BY ${linearityProperty.name.toLowerCase() == linearityProperty.name ? linearityProperty.name : "\"${linearityProperty.name}\""} DESC LIMIT 1";

    String sql =
        "UPDATE ${table.name} SET ($properties) = ($values) WHERE ctid IN ($last)";
    debugPrint(sql);
    try {
      var results = await connection.execute(sql).timeout(timeout);
      debugPrint("updateLastRow: $results");
      if (results == 1)
        return true;
      else
        return false;
    } on PostgreSQLException catch (e) {
      print("updateLastRow: $e");
      return false;
    }
  }

  void getLastRow(app.Table table, {verbose: false}) async {
    Property linearityProperty = table.properties
        .firstWhere((p) => p.definesLinearity, orElse: () => null);
    if (linearityProperty == null) {
      if (verbose)
        debugPrint("getLastRow (${table.name}): No linearity defined");
      return;
    }
    String sql =
        "SELECT * FROM ${table.name} ORDER BY ${linearityProperty.name.toLowerCase() == linearityProperty.name ? linearityProperty.name : "\"${linearityProperty.name}\""} DESC LIMIT 1";
    if (verbose) debugPrint("getLastRow (${table.name}): $sql");
    try {
      List<List<dynamic>> results = await connection.query(sql).timeout(timeout);
      if (verbose) debugPrint("getLastRow: $results");

      table.properties.asMap().forEach((index, p) => p.lastValue = results[0][
          index]); // TODO format accordingly to type / fix postgres plugin bug where array is retrieved badly

    } on PostgreSQLException catch (e) {
      print("getLastRow (${table.name}): $e");
    }
  }

  /// Deleting with ctid I don't need a PK
  // TODO awesome printing usefulness, copy where I can
  @override
  Future<bool> cancelLastInsertion(
      app.Table table, Map<String, String> propertiesForm,
      {verbose: false}) async {
    String whereString = propertiesForm.keys
        .map((e) =>
            "${e.toLowerCase() == e ? e : "\"$e\""} ${propertiesForm[e] == "null" ? "is null" : "= ${propertiesForm[e]}"}")
        .join(" AND ");

    String sql =
        "DELETE FROM ${table.name} WHERE ctid IN (SELECT ctid FROM ${table.name} WHERE $whereString LIMIT 1)";
    if (verbose) debugPrint("cancelLastInsertion (${this.params.alias}): $sql");
    try {
      var results = await connection.execute(sql).timeout(timeout);
      if (verbose) debugPrint("cancelLastInsertion (${this.params.alias}): $results");
      if (results == 1)
        return true;
      else
        return false;
    } on PostgreSQLException catch (e) {
      print(e);
      throw e;
    }
  }

  // TODO nice, copy in the rest of the functions (exceptions, logging...)
  @override
  removeLastEntry(app.Table table, {verbose: true}) async {
    Property linearityProperty = table.properties
        .firstWhere((p) => p.definesLinearity, orElse: () => null);
    if (linearityProperty == null) {
      Exception e = Exception("No linearity defined");
      if (verbose)
        debugPrint("removeLastEntry (${table.name}): ${e.toString()}");
      throw e;
    }
    String sql =
        "DELETE FROM ${table.name} WHERE ctid IN (SELECT ctid FROM ${table.name} ORDER BY ${linearityProperty.name.toLowerCase() == linearityProperty.name ? linearityProperty.name : "\"${linearityProperty.name}\""} DESC LIMIT 1)";
    if (verbose) debugPrint("removeLastEntry (${table.name}): $sql");
    try {
      var results = await connection.execute(sql).timeout(timeout);
      if (verbose) debugPrint("removeLastEntry (${table.name}): $results");
    } on PostgreSQLException catch (e) {
      if (verbose) debugPrint("removeLastEntry (${table.name}): ${e.toString()}");
      throw e;
    }
  }
}
