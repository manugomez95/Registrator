import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/model/property.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:bitacora/utils/db_parameter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLiteClient extends DbClient<Database> {
  SQLiteClient(DbConnectionParams params)
      : super(
          params,
          [
            PrimitiveType.text,
            PrimitiveType.integer,
            PrimitiveType.real,
          ],
        );

  @override
  Future<Database> initConnection() async {
    return openDatabase(
      join(await getDatabasesPath(), params.dbName),
      version: 1,
      onCreate: (db, version) async {
        // Database is created, you can run initial setup here
      },
    );
  }

  @override
  Future<void> openConnection() async {
    // Connection is handled in initConnection
  }

  @override
  Future<void> closeConnection() async {
    await connection.close();
  }

  @override
  Future<bool> checkConnection() async {
    try {
      await connection.query('sqlite_master');
      return true;
    } catch (e) {
      debugPrint('SQLite connection check failed: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getTables({bool verbose = false}) async {
    try {
      final results = await connection.rawQuery(
        'SELECT name FROM sqlite_master WHERE type = "table"'
      );
      return results.map((row) => row['name'] as String).toList();
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
      final results = await connection.rawQuery('PRAGMA table_info($table)');
      final properties = <Property>{};
      
      for (var i = 0; i < results.length; i++) {
        final row = results[i];
        final type = _sqliteTypeToDataType(row['type'] as String);
        
        properties.add(
          Property(
            row['cid'] as int,
            row['name'] as String,
            type,
            row['dflt_value'],
            row['notnull'] == 0,
          ),
        );
      }
      return properties;
    } catch (e) {
      debugPrint('Failed to get properties: $e');
      return {};
    }
  }

  DataType _sqliteTypeToDataType(String sqlType) {
    switch (sqlType.toUpperCase()) {
      case 'INTEGER':
        return DataType(PrimitiveType.integer, sqlType);
      case 'REAL':
        return DataType(PrimitiveType.real, sqlType);
      case 'TEXT':
        return DataType(PrimitiveType.text, sqlType);
      case 'BLOB':
        return DataType(PrimitiveType.byteArray, sqlType);
      default:
        return DataType(PrimitiveType.text, sqlType);
    }
  }

  @override
  Future<void> getKeys() async {
    for (final table in tables) {
      try {
        final foreignKeys = await connection.rawQuery(
          'PRAGMA foreign_key_list(${table.name})',
        );
        
        for (final key in foreignKeys) {
          final property = table.properties.firstWhere(
            (p) => p.name == key['from'],
            orElse: () => throw Exception('Foreign key property not found'),
          );
          
          property.foreignKeyOf = tables.firstWhere(
            (t) => t.name == key['table'],
            orElse: () => throw Exception('Foreign key table not found'),
          );
        }

        final tableInfo = await connection.rawQuery(
          'PRAGMA table_info(${table.name})',
        );
        
        for (final column in tableInfo) {
          if (column['pk'] == 1) {
            table.primaryKey = table.properties.firstWhere(
              (p) => p.name == column['name'],
              orElse: () => throw Exception('Primary key property not found'),
            );
            break;
          }
        }
      } catch (e) {
        debugPrint('Failed to get keys for table ${table.name}: $e');
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
      final results = await connection.rawQuery(
        'SELECT DISTINCT ${table.primaryKey?.name ?? "_rowid_"} '
        'FROM ${table.name} '
        'WHERE ${table.primaryKey?.name ?? "_rowid_"} LIKE ? '
        'ORDER BY ${table.primaryKey?.name ?? "_rowid_"} '
        'LIMIT 10',
        ['%$pattern%'],
      );
      
      return results
          .map((row) => row.values.first?.toString() ?? '')
          .where((value) => value.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Failed to get distinct values: $e');
      return [];
    }
  }

  @override
  String dbStrFormat(String str) => '"$str"';

  @override
  dynamic fromValueToDbValue(dynamic value, DataType type) {
    if (value == null) return null;
    switch (type.primitive) {
      case PrimitiveType.timestamp:
      case PrimitiveType.time:
      case PrimitiveType.date:
        return value is DateTime ? value.toIso8601String() : value.toString();
      case PrimitiveType.boolean:
        return value is bool ? (value ? 1 : 0) : value;
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
      switch (opType) {
        case OpType.insert:
        case OpType.update:
        case OpType.delete:
          return await connection.rawUpdate(command, arguments);
        default:
          return await connection.rawInsert(command, arguments);
      }
    } catch (e) {
      debugPrint('Failed to execute SQL: $e');
      return 0;
    }
  }

  @override
  Future<Map<String, dynamic>> toMap() async {
    final params = await super.toMap();
    params["brand"] = "sqlite";
    return params;
  }

  @override
  SvgPicture getLogo(Brightness brightness) =>
      SvgPicture.asset('assets/images/SQLite.svg',
          height: 75, semanticsLabel: 'SQLite Logo');

  @override
  Future<List<dynamic>> queryLastRow(app.Table table, Property orderBy,
      {bool verbose = false}) async {
    final sql =
        'SELECT * FROM ${table.name} WHERE ${orderBy.name} IS NOT NULL ORDER BY ${orderBy.name} DESC LIMIT 1';
    if (verbose) debugPrint("getLastRow (${table.name}): $sql");
    
    final results = await connection.rawQuery(sql);
    if (results.isEmpty) return [];
    
    return results.first.values.toList();
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
      case PrimitiveType.date:
        return DateTime.parse(result.toString());
      case PrimitiveType.time:
        return TimeOfDay.fromDateTime(DateTime.parse(result.toString()));
      case PrimitiveType.boolean:
        return result == 1;
      default:
        return result;
    }
  }

  @override
  String insertSQL(app.Table table, String properties, String values) {
    return "INSERT INTO ${table.name} ($properties) VALUES ($values)";
  }

  @override
  String editLastFromSQL(app.Table table) {
    final propertiesNames = table.properties.map((e) => dbStrFormat(e.name)).join(", ");
    final valuesString = List.filled(table.properties.length, "?").join(", ");
    final where = table.properties
        .map((p) => "${dbStrFormat(p.name)} ${p.lastValue == null ? 'IS NULL' : '= ?'}")
        .join(" AND ");

    return "UPDATE ${table.name} SET ($propertiesNames) = ($valuesString) WHERE $where";
  }

  @override
  String deleteLastFromSQL(app.Table table) {
    final where = table.properties
        .map((p) => "${dbStrFormat(p.name)} ${p.lastValue == null ? 'IS NULL' : '= ?'}")
        .join(" AND ");

    return "DELETE FROM ${table.name} WHERE $where";
  }
}
