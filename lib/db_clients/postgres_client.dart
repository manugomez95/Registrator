import 'dart:typed_data';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/model/property.dart';
import 'package:flutter/cupertino.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:postgres/postgres.dart';
import 'package:bitacora/utils/db_parameter.dart';

/// IMPORTANT: Not using getIt<AppData> in this file, this kind of logic is better in the bloc
/// Simplify as much as possible, good for using many dbs, the hard work will be in the general code

extension PgString on String {

  // TODO fix unsupported Arrays -> Basically fix postgres library
  DataType toDataType({String udtName, isArray: false}) {
    String arrayStr = isArray ? "[ ]" : "";
    switch (this) {
      case "timestamp without time zone":
      case "_timestamp":
      case "timestamp with time zone":
      case "_timestamptz":
        if (isArray) throw UnsupportedError("$this not supported as a type");
        return DataType(PrimitiveType.timestamp, "timestamp" + arrayStr,
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
        if (isArray) throw UnsupportedError("$this not supported as a type");
        return DataType(PrimitiveType.integer, "integer" + arrayStr,
            isArray: isArray);
      case "smallint":
      case "_int2":
        if (isArray) throw UnsupportedError("$this not supported as a type");
        return DataType(PrimitiveType.smallInt, "smallInt" + arrayStr,
            isArray: isArray);
      case "bigint":
      case "_int8":
        if (isArray) throw UnsupportedError("$this not supported as a type");
        return DataType(PrimitiveType.bigInt, "bigInt" + arrayStr,
            isArray: isArray);
      case "boolean":
      case "_bool":
        if (isArray) throw UnsupportedError("$this not supported as a type");
        return DataType(PrimitiveType.boolean, "boolean" + arrayStr,
            isArray: isArray);
      case "real":
      case "_float4":
        if (isArray) throw UnsupportedError("$this not supported as a type");
        return DataType(PrimitiveType.real, "real" + arrayStr,
            isArray: isArray);
      case "date":
      case "_date":
        if (isArray) throw UnsupportedError("$this not supported as a type");
        return DataType(PrimitiveType.date, "date" + arrayStr,
            isArray: isArray);
      case "oid":
      case "_oid":
        if (isArray) throw UnsupportedError("$this not supported as a type");
        return DataType(PrimitiveType.byteArray, "oid" + arrayStr,
            isArray: isArray);
      //Todo ENUMS case "USER-DEFINED": and support array
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
  PostgresClient._(DbConnectionParams params, List<PrimitiveType> orderByTypes)
      : super(params, orderByTypes);

  factory PostgresClient(DbConnectionParams params) {
    List<PrimitiveType> orderByTypes = [
      PrimitiveType.date,
      PrimitiveType.timestamp,
      PrimitiveType.time,
    ];
    return PostgresClient._(params, orderByTypes);
  }

  @override
  Future<Map<String, dynamic>> toMap() async {
    Map<String, dynamic> params = await super.toMap();
    params["brand"] = "postgres";
    return params;
  }

  @override
  SvgPicture getLogo(Brightness brightness) =>
      SvgPicture.asset('assets/images/postgresql_elephant.svg',
          height: 75, semanticsLabel: 'Postgres Logo');

  @override
  initConnection() async {
    return PostgreSQLConnection(params.host, params.port, params.dbName,
        username: params.username,
        password: params.password,
        useSSL: params.useSSL,
        timeoutInSeconds: timeout.inSeconds,
        queryTimeoutInSeconds: queryTimeout.inSeconds);
  }

  @override
  openConnection() async {
    await connection.open();
  }

  @override
  closeConnection() async {
    await connection?.close()?.timeout(timeout);
  }

  Future<List<String>> getTables({verbose: false}) async {
    List<List<dynamic>> tablesResponse = await connection.query(
        r"SELECT table_name "
        r"FROM information_schema.tables "
        r"WHERE table_type = 'BASE TABLE' "
        r"AND table_schema = @tableSchema",
        substitutionValues: {"tableSchema": "public"}).timeout(timeout);

    List<String> tablesNames =
        tablesResponse.expand((i) => i).toList().cast<String>();
    return tablesNames;
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
          res[0],
          res[1],
          res[2].toString().toDataType(udtName: res[6]),
          res[3],
          res[4] == 'YES' ? true : false,
          charMaxLength: res[5]));
    }

    return properties;
  }

  @override
  Future<bool> checkConnection() async {
    String sql = "select 1 from information_schema.columns limit 1";
    return await connection.query(sql) != null;
  }

  @override
  Future<List> queryLastRow(app.Table table, Property orderBy,
      {verbose = false}) async {
    String sql =
        "SELECT * FROM ${dbStrFormat(table.name)} WHERE ${dbStrFormat(orderBy.name)} IS NOT NULL ORDER BY ${dbStrFormat(orderBy.name)} DESC LIMIT 1";
    if (verbose) debugPrint("getLastRow (${table.name}): $sql");
    return (await connection.query(sql).timeout(timeout))[0];
  }

  @override
  dynamic resToValue(dynamic result, DataType type, {bool fromArray = false}) {
    // TODO array not working for all types
    if (type.isArray && !fromArray && result != null) {
      List<int> codes;

      /// We assume is always a String except when is null
      if (result is String)
        codes = result.codeUnits.sublist(24);
      else
        codes = result.toList().sublist(24);
      List<List<int>> list = [];
      List<int> lastElem = [];
      for (final c in codes) {
        if (c < 32) {
          if (lastElem.isNotEmpty) {
            list.add(lastElem);
            lastElem = [];
          }
        } else
          lastElem.add(c);
      }
      list.add(lastElem);
      return list
          .map(
              (e) => resToValue(String.fromCharCodes(e), type, fromArray: true))
          .toList();
    } else if (type.primitive == PrimitiveType.byteArray) {
      return fromBytesToInt32(result[0], result[1], result[2], result[3]);
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

  @override
  insertSQL(app.Table table, String properties, String values) {
  return "INSERT INTO ${dbStrFormat(table.name)} ($properties) VALUES ($values)";
  }

  @override
  String editLastFromSQL(app.Table table) {
    String propertiesNames = table.properties.map((e) => dbStrFormat(e.name)).join(", ");
    String valuesString = List.filled(table.properties.length, "?").join(", ");

    /// last values, IMPORTANT, when null there's no question mark so...
    String where = "WHERE " +
        table.properties.map((Property p) {
          return "${dbStrFormat(p.name)} ${p.lastValue == null ? "is null" : "= ?"}";
        }).join(" AND ");

    String last =
        "SELECT ctid FROM ${dbStrFormat(table.name)} $where LIMIT 1";

    return "UPDATE ${table.name} SET ($propertiesNames) = ($valuesString) WHERE ctid IN ($last)";
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
              ?.foreignKeyOf =
          tables?.firstWhere((t) => t.name == result[4], orElse: () => null));

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
    String pk = dbStrFormat(table.primaryKey.name);
    String sql =
        "SELECT DISTINCT $pk FROM ${dbStrFormat(table.name)} WHERE $pk LIKE '%$pattern%';";
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

  /// Deleting with ctid I don't need order by
  @override
  Future<int> executeCancelLastInsertion(app.Table table, String whereString, {verbose: false}) async {
    String sql =
        "DELETE FROM ${dbStrFormat(table.name)} WHERE ctid IN (SELECT ctid FROM ${dbStrFormat(table.name)} WHERE $whereString LIMIT 1)";
    if (verbose) debugPrint("cancelLastInsertion (${this.params.alias}): $sql");
    return await connection.execute(sql);
  }

  @override
  fromValueToDbValue(dynamic value, DataType type, {bool fromArray: false, bool inWhere: false}) {
    /// IMPORTANT
    if (value == null || value.toString() == "")
      return null;
    else if (type.isArray && !fromArray)
      return (value as List).isEmpty
          ? null
          : "{${(value as List).map((e) => fromValueToDbValue(e, type, fromArray: true)).join(", ")}}";
    else {
      if ([
            PrimitiveType.date,
            PrimitiveType.timestamp,
            PrimitiveType.time,
          ].contains(type.primitive) &&
          !fromArray)
        return "'${value.toString()}'";
      else
        return value.toString();
    }
  }

  @override
  String dbStrFormat(String str) {
    return str.toLowerCase() != str || str.contains(" ") ? '''"$str"''' : str;
  }

  @override
  executeSQL(OpType opType, String command, List arguments) async {
    var i = 0;
    var fmtString = command.replaceAllMapped("?", (match) { i++; return "@arg$i"; });
    var substitutionValues = Map.fromIterables(List.generate(arguments.length, (index) => "arg${index+1}"), arguments);
    return await connection.execute(fmtString, substitutionValues: substitutionValues);
  }

  @override
  query(String command, List arguments) async {
    var i = 0;
    var fmtString = command.replaceAllMapped("?", (match) { i++; return "@arg$i"; });
    var substitutionValues = Map.fromIterables(List.generate(arguments.length, (index) => "arg${index+1}"), arguments);
    return await connection.query(fmtString, substitutionValues: substitutionValues);
  }

  @override
  String deleteLastFromSQL(app.Table table) {
    /// last values, IMPORTANT, when null there's no question mark so...
    String where = "WHERE " +
        table.properties.map((Property p) {
          return "${dbStrFormat(p.name)} ${p.lastValue == null ? "is null" : "= ?"}";
        }).join(" AND ");

    return "DELETE FROM ${dbStrFormat(table.name)} WHERE ctid IN "
        "(SELECT ctid FROM ${dbStrFormat(table.name)} $where LIMIT 1)";
  }
}