import 'dart:ui';
import 'package:bitacora/model/property.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';
import 'db_client.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/bigquery/v2.dart' as bq;

extension BQString on String {
  DataType toDataType({required String udtName, bool isArray = false}) {
    switch (udtName) {
      case "STRING":
        return DataType(PrimitiveType.text, udtName, isArray: isArray);
      case "INTEGER":
      case "INT64":
        return DataType(PrimitiveType.integer, udtName, isArray: isArray);
      case "FLOAT":
      case "FLOAT64":
        return DataType(PrimitiveType.real, udtName, isArray: isArray);
      case "BOOLEAN":
      case "BOOL":
        return DataType(PrimitiveType.boolean, udtName, isArray: isArray);
      case "TIMESTAMP":
        return DataType(PrimitiveType.timestamp, udtName, isArray: isArray);
      case "TIME":
        return DataType(PrimitiveType.time, udtName, isArray: isArray);
      case "DATE":
        return DataType(PrimitiveType.date, udtName, isArray: isArray);
      case "BYTES":
        return DataType(PrimitiveType.byteArray, udtName, isArray: isArray);
      default:
        throw UnsupportedError("Type not supported: $udtName");
    }
  }
}

// ignore: must_be_immutable
class BigQueryClient extends DbClient<bq.BigqueryApi> {
  final String projectId;
  final String datasetId;
  final ServiceAccountCredentials _credentials;

  BigQueryClient(DbConnectionParams params)
      : projectId = params.host,
        datasetId = params.dbName,
        _credentials = ServiceAccountCredentials.fromJson({
          'private_key': params.password,
          'client_email': params.username,
          'private_key_id': '',
          'client_id': '',
          'type': 'service_account',
        }),
        super(
          params,
          [
            PrimitiveType.text,
            PrimitiveType.integer,
            PrimitiveType.real,
            PrimitiveType.boolean,
            PrimitiveType.timestamp,
            PrimitiveType.time,
            PrimitiveType.date,
            PrimitiveType.byteArray,
          ],
        );

  @override
  Future<bq.BigqueryApi> initConnection() async {
    final scopes = [bq.BigqueryApi.bigqueryScope];
    final httpClient = await clientViaServiceAccount(_credentials, scopes);
    return bq.BigqueryApi(httpClient);
  }

  @override
  Future<void> openConnection() async {
    // Connection is handled by the client
  }

  @override
  Future<void> closeConnection() async {
    // Connection is handled by the client
  }

  @override
  Future<bool> checkConnection() async {
    try {
      await connection.datasets.list(projectId);
      return true;
    } catch (e) {
      debugPrint('BigQuery connection check failed: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getTables({bool verbose = false}) async {
    try {
      final response = await connection.tables.list(projectId, datasetId);
      final tables = response.tables;
      if (tables == null) return [];
      
      return tables
          .map((table) => table.tableReference?.tableId ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Failed to get tables: $e');
      return [];
    }
  }

  @override
  Future<Set<Property>> getPropertiesFromTable(
    String table, {
    bool verbose = false,
  }) async {
    try {
      final tableData = await connection.tables.get(projectId, datasetId, table);
      final schema = tableData.schema;
      if (schema == null || schema.fields == null) return {};

      final properties = <Property>{};
      for (var i = 0; i < schema.fields!.length; i++) {
        final field = schema.fields![i];
        if (field.name == null || field.type == null) continue;

        final type = field.type!.toDataType(udtName: field.type!);
        properties.add(
          Property(
            i,
            field.name!,
            type,
            field.defaultValueExpression,
            field.mode == 'NULLABLE',
          ),
        );
      }
      return properties;
    } catch (e) {
      debugPrint('Failed to get properties: $e');
      return {};
    }
  }

  @override
  Future<void> getKeys() async {
    // BigQuery doesn't support primary/foreign keys in the same way as traditional databases
    // We'll use the first column as the primary key by default
    for (final table in tables) {
      if (table.properties.isNotEmpty) {
        table.primaryKey = table.properties.first;
      }
    }
  }

  @override
  Future<List<String>> getPkDistinctValues(
    app.Table table, {
    bool verbose = false,
    String? pattern,
  }) async {
    if (pattern == null || pattern.isEmpty) {
      return [];
    }

    try {
      final queryRequest = bq.QueryRequest()
        ..query = '''
          SELECT DISTINCT ${table.primaryKey?.name ?? '_PARTITIONTIME'} 
          FROM `$projectId.$datasetId.${table.name}`
          WHERE ${table.primaryKey?.name ?? '_PARTITIONTIME'} LIKE '%$pattern%'
          ORDER BY ${table.primaryKey?.name ?? '_PARTITIONTIME'}
          LIMIT 10
        ''';

      final response = await connection.jobs.query(queryRequest, projectId);
      final rows = response.rows;
      if (rows == null) return [];

      return rows.map((row) => row.f?[0].v?.toString() ?? '').where((v) => v.isNotEmpty).toList();
    } catch (e) {
      debugPrint('Failed to get distinct values: $e');
      return [];
    }
  }

  @override
  String dbStrFormat(String str) => '`$str`';

  @override
  dynamic fromValueToDbValue(dynamic value, DataType type) {
    if (value == null) return null;
    switch (type.primitive) {
      case PrimitiveType.timestamp:
      case PrimitiveType.time:
      case PrimitiveType.date:
        return value is DateTime ? value.toIso8601String() : value.toString();
      default:
        return value.toString();
    }
  }

  @override
  Future<int> executeSQL(
    OpType opType,
    String command,
    List<dynamic> arguments,
  ) async {
    try {
      final queryRequest = bq.QueryRequest()..query = command;
      final response = await connection.jobs.query(queryRequest, projectId);
      return int.tryParse(response.numDmlAffectedRows ?? '0') ?? 0;
    } catch (e) {
      debugPrint('Failed to execute SQL: $e');
      return 0;
    }
  }

  @override
  Future<Map<String, dynamic>> toMap() async {
    final params = await super.toMap();
    params["brand"] = "bigquery";
    return params;
  }

  @override
  SvgPicture getLogo(Brightness brightness) =>
      SvgPicture.asset('assets/images/BigQuery.svg',
          height: 75, semanticsLabel: 'BigQuery Logo');

  @override
  Future<List<dynamic>> queryLastRow(app.Table table, Property orderBy,
      {bool verbose = false}) async {
    final sql =
        "SELECT * FROM `$projectId.$datasetId.${table.name}` WHERE ${orderBy.name} IS NOT NULL ORDER BY ${orderBy.name} DESC LIMIT 1";
    if (verbose) debugPrint("getLastRow (${table.name}): $sql");
    
    final queryRequest = bq.QueryRequest()..query = sql;
    final response = await connection.jobs.query(queryRequest, projectId);
    if (response.rows == null || response.rows!.isEmpty) return [];
    
    return response.rows!.first.f?.map((f) => f.v).toList() ?? [];
  }

  @override
  dynamic resToValue(dynamic result, DataType type, {bool fromArray = false}) {
    if (result == null) return null;
    
    if (type.isArray && !fromArray) {
      final List<dynamic> array = result as List;
      if (array.isEmpty) return null;
      return array.map((e) => resToValue(e, type, fromArray: true)).toList();
    }

    switch (type.primitive) {
      case PrimitiveType.timestamp:
        return DateTime.parse(result);
      case PrimitiveType.date:
        return DateTime.parse(result);
      case PrimitiveType.time:
        return TimeOfDay.fromDateTime(DateTime.parse(result));
      default:
        return result;
    }
  }

  @override
  String insertSQL(app.Table table, String properties, String values) {
    return "INSERT INTO `$projectId.$datasetId.${table.name}` ($properties) VALUES ($values)";
  }

  @override
  String editLastFromSQL(app.Table table) {
    final propertiesNames = table.properties.map((e) => dbStrFormat(e.name)).join(", ");
    final valuesString = List.filled(table.properties.length, "?").join(", ");
    final where = table.properties
        .map((p) => "${dbStrFormat(p.name)} ${p.lastValue == null ? 'IS NULL' : '= ?'}")
        .join(" AND ");

    return "UPDATE `$projectId.$datasetId.${table.name}` SET ($propertiesNames) = ($valuesString) WHERE $where";
  }

  @override
  String deleteLastFromSQL(app.Table table) {
    final where = table.properties
        .map((p) => "${dbStrFormat(p.name)} ${p.lastValue == null ? 'IS NULL' : '= ?'}")
        .join(" AND ");

    return "DELETE FROM `$projectId.$datasetId.${table.name}` WHERE $where";
  }
}
