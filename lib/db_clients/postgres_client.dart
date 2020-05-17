import 'dart:typed_data';
import 'package:bitacora/bloc/database/bloc.dart';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/model/property.dart';
import 'package:flutter/cupertino.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:flutter_svg/svg.dart';
import 'package:postgres/postgres.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:sqflite/sqflite.dart';

/// IMPORTANT: Not using getIt<AppData> in this file, this kind of logic is better in the bloc
/// Simplify as much as possible, good for using many dbs, the hard work will be in the general code

extension PgString on String {
  String pgFormat() {
    return this.toLowerCase() != this || this.contains(" ")
        ? '''"$this"'''
        : this;
  }

  static fromPgValue(dynamic value, DataType type, {bool fromArray = false}) {
    if (value == null || value.toString() == "")
      return 'null';
    else if (type.isArray && !fromArray)
      return (value as List).isEmpty
          ? 'null'
          : "'{${(value as List).map((e) => PgString.fromPgValue(e, type, fromArray: true)).join(", ")}}'";
    else {
      if ([
        PrimitiveType.text,
        PrimitiveType.varchar,
        PrimitiveType.date,
        PrimitiveType.timestamp,
        PrimitiveType.time,
      ].contains(type.primitive) && !fromArray)
        return "'${value.toString()}'";
      else
        return value.toString();
    }
  }

  DataType toDataType({String udtName, isArray: false}) {
    String arrayStr = isArray ? "[ ]" : "";
    switch (this) {
      case "timestamp without time zone":
      case "_timestamp":
      case "timestamp with time zone":
      case "_timestamptz":
        return DataType(PrimitiveType.timestamp, "timestamp" + arrayStr,
            isArray: isArray);
      case "time without time zone":
      case "_time":
      case "time with time zone":
      case "_timetz":
      return DataType(PrimitiveType.time, "time" + arrayStr,
          isArray: isArray);
      case "character varying":
      case "_varchar":
        return DataType(PrimitiveType.varchar, "varchar" + arrayStr,
            isArray: isArray);
      case "text":
      case "_text":
        return DataType(PrimitiveType.text, "text" + arrayStr,
            isArray: isArray);
      case "integer":
      case "_int4":
        return DataType(PrimitiveType.integer, "integer" + arrayStr,
            isArray: isArray);
      case "smallint":
      case "_int2":
        return DataType(PrimitiveType.smallInt, "smallInt" + arrayStr,
            isArray: isArray);
      case "bigint":
      case "_int8":
        return DataType(PrimitiveType.bigInt, "bigInt" + arrayStr,
            isArray: isArray);
      case "boolean":
      case "_bool":
        return DataType(PrimitiveType.boolean, "boolean" + arrayStr,
            isArray: isArray);
      case "real":
      case "_float4":
        return DataType(PrimitiveType.real, "real" + arrayStr,
            isArray: isArray);
      case "date":
      case "_date":
        return DataType(PrimitiveType.date, "date" + arrayStr,
            isArray: isArray);
      case "oid":
      case "_oid":
        return DataType(PrimitiveType.byteArray, "oid" + arrayStr,
            isArray: isArray);
      //Todo ENUMS case "USER-DEFINED":
      //  SELECT pg_type.typname AS enumtype,
      //     pg_enum.enumlabel AS enumlabel
      // FROM pg_type
      // JOIN pg_enum
      //     ON pg_enum.enumtypid = pg_type.oid;
      case "ARRAY":
        return udtName.toDataType(isArray: true);
      default:
        throw UnsupportedError("$this not supported as a type");
    }
  }
}

// ignore: must_be_immutable
class PostgresClient extends DbClient<PostgreSQLConnection> {
  PostgresClient(DbConnectionParams params,
      {Duration timeout: const Duration(seconds: 3),
      Duration queryTimeout: const Duration(seconds: 2)})
      : super(params, timeout: timeout, queryTimeout: queryTimeout) {
    connection = PostgreSQLConnection(params.host, params.port, params.dbName,
        username: params.username,
        password: params.password,
        useSSL: params.useSSL,
        timeoutInSeconds: timeout.inSeconds,
        queryTimeoutInSeconds: queryTimeout.inSeconds);
  }

  @override
  SvgPicture getLogo(Brightness brightness) =>
      SvgPicture.asset('assets/images/postgresql_elephant.svg',
          height: 75, semanticsLabel: 'Postgres Logo');

  @override
  Future<Map<String, dynamic>> toMap() async {
    Map<String, dynamic> params = await super.toMap();
    params["brand"] = "postgres";
    return params;
  }

  /// Always call asynchronously
  @override
  connect({verbose: false}) async {
    if (connection == null) {
      connection = PostgreSQLConnection(params.host, params.port, params.dbName,
          username: params.username,
          password: params.password,
          useSSL: params.useSSL,
          timeoutInSeconds: timeout.inSeconds,
          queryTimeoutInSeconds: queryTimeout.inSeconds);
    }
    await connection.open();
    isConnected = true;
    if (verbose)
      debugPrint("connect (${this.params.alias}): Connection established");
  }

  @override
  disconnect({verbose: false}) async {
    try {
      await connection?.close()?.timeout(timeout);
      if (verbose) debugPrint("disconnect (${this.params.alias}): completed");
    } on Exception catch (e) {
      if (verbose) debugPrint("disconnect (${this.params.alias}): $e");
    } finally {
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
    } on Exception catch (e) {
      if (verbose) debugPrint("ping (${this.params.alias}): not connected");
      await disconnect();
      databaseBloc.add(ConnectionErrorEvent(e, this));
    } finally {
      // ignore: control_flow_in_finally
      return isConnected;
    }
  }

  @override
  pullDatabaseModel({verbose: false, getLastRows: true}) async {
    if (verbose) {
      if (this.tables != null)
        debugPrint("pullDatabaseModel (${this.params.alias}): Updating model");
      else
        debugPrint(
            "pullDatabaseModel (${this.params.alias}): Getting model for the first time");
    }

    /// Get tables
    List<String> tablesNames = await getTables(verbose: verbose);

    // TODO get user defined types (for enum)

    /// For each table:
    Set<app.Table> tables = Set();
    for (var tName in tablesNames) {
      /// get properties...
      try {
        Set<Property> properties = await getPropertiesFromTable(tName);

        tables.add(app.Table(tName, properties, this));

        /// if first time loading DB model identify the "ORDER BY field", since Postgres has a date and timestamp type
        if (this.tables == null) {
          var orderByCandidates = properties.where((property) => [
                PrimitiveType.date,
                PrimitiveType.timestamp,
                PrimitiveType.time,
              ].contains(property.type.primitive));
          if (orderByCandidates.length == 1)
            tables.last.orderBy = orderByCandidates.first;
        }

        await tables.last.save(conflictAlgorithm: ConflictAlgorithm.ignore);
      } on UnsupportedError catch (e) {
        print(e);
        continue;
        // TODO mark table with Unsupported label? Show toast or something
      }

      /// [optionally] and get last row
      if (getLastRows) await getLastRow(tables.last);
    }

    this.tables = tables;

    /// get foreign and primary keys info
    await getKeys();

    if (verbose) debugPrint("updateDatabaseModel: ${this.tables.toString()}");
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

      if (verbose)
        debugPrint(
            "getTables (${this.params.alias}): ${tablesNames.toString()}");
      return tablesNames;
    } on PostgreSQLException catch (e) {
      debugPrint(e.toString());
      throw e;
    }
  }

  @override
  Future<Set<Property>> getPropertiesFromTable(String table,
      {verbose: false}) async {
    List<List<dynamic>> results = await connection.query(
        r"SELECT ordinal_position, column_name, data_type, column_default, is_nullable, character_maximum_length, udt_name FROM information_schema.columns "
        r"WHERE table_schema = @tableSchema AND table_name   = @tableName",
        substitutionValues: {
          "tableSchema": "public",
          "tableName": table
        }).timeout(timeout);

    Set<Property> properties = Set();
    for (final res in results) {
      properties.add(Property(
          res[0] - 1,
          res[1],
          res[2].toString().toDataType(udtName: res[6]),
          res[3],
          res[4] == 'YES' ? true : false,
          charMaxLength: res[5]));
    }

    return properties;
  }

  @override
  Future<bool> insertRowIntoTable(
      app.Table table, Map<Property, dynamic> propertiesForm,
      {verbose: false}) async {
    String properties =
        propertiesForm.keys.map((Property p) => p.name.pgFormat()).join(", ");
    String values = propertiesForm.keys
        .map((Property p) => PgString.fromPgValue(propertiesForm[p], p.type))
        .join(", ");

    String sql =
        "INSERT INTO ${table.toString()} ($properties) VALUES ($values)";
    if (verbose) debugPrint(sql);
    try {
      var results = await connection.execute(sql).timeout(timeout);
      if (verbose) debugPrint("insertRowIntoTable: $results");
      if (results == 1) {
        /// Update official last row
        table.properties.forEach((p) => p.lastValue = propertiesForm[p]);
        return true;
      } else
        return false;
    } on PostgreSQLException catch (e) {
      if (verbose) debugPrint(e.toString());
      throw e;
    }
  }

  /// I will always check the lastValues to avoid editing an incorrect row.
  editLastFrom(app.Table table, Map<Property, dynamic> propertiesForm,
      {verbose: false}) async {
    Property orderBy = table.orderBy;

    /// if there's no order nor last values...
    if (orderBy == null && table.properties.every((p) => p.lastValue == null)) {
      String exception = "No linearity nor lastValue defined";
      if (verbose) debugPrint("editLastFrom (${table.name}): $exception");
      throw Exception(exception);
    }

    /// last values
    String where = "WHERE " +
        table.properties.map((Property p) {
          var valueStr = PgString.fromPgValue(p.lastValue, p.type);
          return "${p.name.pgFormat()} ${valueStr == "null" ? "is null" : "= $valueStr"}";
        }).join(" AND ");

    /// this are the new values
    String properties =
        propertiesForm.keys.map((Property p) => p.name.pgFormat()).join(", ");
    String values = propertiesForm.keys
        .map((p) => PgString.fromPgValue(propertiesForm[p], p.type))
        .join(", ");

    /// if orderBy is used
    String order =
        orderBy != null ? "ORDER BY ${orderBy.name.pgFormat()} DESC" : "";

    String last =
        "SELECT ctid FROM ${table.name.pgFormat()} $where $order LIMIT 1";

    String sql =
        "UPDATE ${table.name} SET ($properties) = ($values) WHERE ctid IN ($last)";

    if (verbose) debugPrint(sql);

    try {
      var results = await connection.execute(sql).timeout(timeout);
      debugPrint("editLastFrom (${table.name}): $results");
      if (results == 1) {
        /// Update official last row
        table.properties.forEach((p) => p.lastValue = propertiesForm[p]);
        return true;
      } else
        return false;
    } on PostgreSQLException catch (e) {
      if (verbose) debugPrint("editLastFrom (${table.name}): ${e.toString()}");
      throw e;
    }
  }

  getLastRow(app.Table table, {verbose: false}) async {
    Property linearityProperty = table.orderBy;
    if (linearityProperty == null) {
      if (verbose)
        debugPrint("getLastRow (${table.name}): No linearity defined");
      return;
    }

    String sql =
        "SELECT * FROM ${table.name.pgFormat()} WHERE ${linearityProperty.name.pgFormat()} IS NOT NULL ORDER BY ${linearityProperty.name.pgFormat()} DESC LIMIT 1";
    if (verbose) debugPrint("getLastRow (${table.name}): $sql");
    try {
      List<List<dynamic>> results =
          await connection.query(sql).timeout(timeout);
      if (verbose) debugPrint("getLastRow: $results");
      if (results.isNotEmpty) {
        for (final p in table.properties) {
          p.lastValue = resultToValue(p.type, results[0][p.dbPosition]);
        }
      } else {
        table.properties.forEach((p) => p.lastValue = null);
      }
    } on PostgreSQLException catch (e) {
      print("getLastRow (${table.name}): $e");
    }
  }

  dynamic resultToValue(DataType type, dynamic result, {bool fromArray = false}) {
    if (type.isArray && !fromArray && result != null) {

      List<int> codes;
      if (result is String) codes = result.codeUnits.sublist(24);
      else codes = result.toList().sublist(24);

      codes.removeWhere((c) => c == 0);
      List<List<int>> list = [];
      List<int> lastElem = [];
      for (final c in codes) {
        if (c < 32) {
          list.add(lastElem);
          lastElem = [];
        } else
          lastElem.add(c);
      }
      list.add(lastElem);
      return list.map((e) => resultToValue(type, String.fromCharCodes(e), fromArray: true)).toList();
    }
    else if (type.primitive == PrimitiveType.byteArray) {
      return fromBytesToInt32(
          result[0],
          result[1],
          result[2],
          result[3]);
    } else {
      return result;
    }
  }

  int fromBytesToInt32(int b3, int b2, int b1, int b0) {
    final int8List = Int8List(4)
      ..[3] = b3
      ..[2] = b2
      ..[1] = b1
      ..[0] = b0;
    return ByteData.view(int8List.buffer).getUint32(0, Endian.little);
  }

  /// Table properties need to be already created and also the rest of the tables
  getKeys({verbose: false}) async {
    String sqlForeign = "SELECT tc.table_schema, "
        "tc.table_name, "
        "kcu.column_name, "
        "ccu.table_schema AS foreign_table_schema, "
        "ccu.table_name AS foreign_table_name, "
        "ccu.column_name AS foreign_column_name "
        "FROM information_schema.table_constraints AS tc "
        "JOIN information_schema.key_column_usage AS kcu "
        "ON tc.constraint_name = kcu.constraint_name "
        "AND tc.table_schema = kcu.table_schema "
        "JOIN information_schema.constraint_column_usage AS ccu "
        "ON ccu.constraint_name = tc.constraint_name "
        "AND ccu.table_schema = tc.table_schema "
        "WHERE tc.constraint_type = 'FOREIGN KEY';";

    String sqlPrimary =
        "SELECT tc.table_schema, tc.table_name, ccu.column_name FROM information_schema.table_constraints as tc JOIN "
        "information_schema.constraint_column_usage AS ccu "
        "ON ccu.constraint_name = tc.constraint_name WHERE tc.constraint_type = 'PRIMARY KEY';";

    try {
      // get foreign keys
      List<List<dynamic>> foreign =
          await connection.query(sqlForeign).timeout(timeout);
      if (verbose) debugPrint("getKeys: $foreign");

      foreign.forEach((result) => tables
          .firstWhere((t) => t.name == result[1], orElse: () => null)
          ?.properties
          ?.firstWhere((e) => e.name == result[2])
          ?.foreignKeyOf = tables?.firstWhere((t) => t.name == result[4]));

      // get primary keys
      List<List<dynamic>> primary =
          await connection.query(sqlPrimary).timeout(timeout);
      if (verbose) debugPrint("getKeys: $primary");

      for (final result in primary) {
        app.Table table =
            tables.firstWhere((t) => t.name == result[1], orElse: () => null);
        if (table != null) {
          table.primaryKey =
              table.properties.firstWhere((p) => p.name == result[2]);
        }
      }
    } on PostgreSQLException catch (e) {
      print("getKeys: $e");
    }
  }

  Future<List<String>> getPkDistinctValues(app.Table table,
      {verbose: false, String pattern}) async {
    if (pattern == "") return null;
    String pk = table.primaryKey.name.pgFormat();
    String sql =
        "SELECT DISTINCT $pk FROM ${table.name.pgFormat()} WHERE $pk LIKE '%$pattern%';";
    try {
      List<List<dynamic>> results =
          await connection.query(sql).timeout(timeout);
      if (verbose) debugPrint("getPkDistinctValues: $results");

      return results.expand((i) => i).toList().cast<String>();
    } on PostgreSQLException catch (e) {
      debugPrint("getForeignKeys: $e");
      return null;
    }
  }

  /// Deleting with ctid I don't need a PK
  @override
  cancelLastInsertion(app.Table table, Map<Property, dynamic> propertiesForm,
      {verbose: false}) async {
    String whereString = propertiesForm.keys.map((Property p) {
      var valueStr = PgString.fromPgValue(propertiesForm[p], p.type);
      return "${p.name.pgFormat()} ${valueStr == "null" ? "is null" : "= $valueStr"}";
    }).join(" AND ");

    String sql =
        "DELETE FROM ${table.name.pgFormat()} WHERE ctid IN (SELECT ctid FROM ${table.name.pgFormat()} WHERE $whereString LIMIT 1)";

    if (verbose) debugPrint("cancelLastInsertion (${this.params.alias}): $sql");
    try {
      var results = await connection.execute(sql).timeout(timeout);

      if (verbose)
        debugPrint("cancelLastInsertion (${this.params.alias}): $results");
    } on PostgreSQLException catch (e) {
      print(e);
      throw e;
    }
  }

  /// https://stackoverflow.com/questions/5170546/how-do-i-delete-a-fixed-number-of-rows-with-sorting-in-postgresql
  @override
  deleteLastFrom(app.Table table, {verbose: false}) async {
    Property orderBy = table.orderBy;

    /// if there's no order nor last values...
    if (orderBy == null && table.properties.every((p) => p.lastValue == null)) {
      String exception = "No linearity nor lastValue defined";
      if (verbose) debugPrint("deleteLastFrom (${table.name}): $exception");
      throw Exception(exception);
    }

    /// last values
    String where = "WHERE " +
        table.properties.map((Property p) {
          var valueStr = PgString.fromPgValue(p.lastValue, p.type);
          return "${p.name.pgFormat()} ${valueStr == "null" ? "is null" : "= $valueStr"}";
        }).join(" AND ");

    /// if orderBy is used
    String order =
        orderBy != null ? "ORDER BY ${orderBy.name.pgFormat()} DESC" : "";

    String last =
        "SELECT ctid FROM ${table.name.pgFormat()} $where $order LIMIT 1";

    String sql = "DELETE FROM ${table.name} WHERE ctid IN ($last)";

    if (verbose) debugPrint("removeLastEntry (${table.name}): $sql");

    try {
      var results = await connection.execute(sql).timeout(timeout);
      if (results == 0) {
        throw Exception("Table is empty");
      }

      if (verbose) debugPrint("removeLastEntry (${table.name}): $results");
    } on PostgreSQLException catch (e) {
      if (verbose)
        debugPrint("removeLastEntry (${table.name}): ${e.toString()}");
      throw e;
    }
  }

  // TODO maybe doesn't make much sense
  @override
  setConnectionParams(DbConnectionParams params, {verbose}) async {
    connection = PostgreSQLConnection(params.host, params.port, params.dbName,
        username: params.username,
        password: params.password,
        useSSL: params.useSSL,
        timeoutInSeconds: timeout.inSeconds,
        queryTimeoutInSeconds: queryTimeout.inSeconds);
  }
}
