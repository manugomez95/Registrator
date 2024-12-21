import 'dart:typed_data';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/model/property.dart';
import 'package:flutter/cupertino.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:postgres/postgres.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:flutter/foundation.dart';

/// IMPORTANT: Not using getIt<AppData> in this file, this kind of logic is better in the bloc
/// Simplify as much as possible, good for using many dbs, the hard work will be in the general code

extension PgString on String {

  // TODO fix unsupported Arrays -> Basically fix postgres library
  DataType toDataType({required String udtName, bool isArray = false}) {
    final arrayStr = isArray ? "[ ]" : "";
    switch (this) {
      case "timestamp without time zone":
      case "_timestamp":
      case "timestamp with time zone":
      case "_timestamptz":
        if (isArray) throw UnsupportedError("$this not supported as a type");
        return DataType(PrimitiveType.timestamp, "timestamp$arrayStr",
            isArray: isArray);
      case "character varying":
      case "_varchar":
        return DataType(PrimitiveType.varchar, "varchar$arrayStr",
            isArray: isArray);
      case "text":
      case "_text":
        return DataType(PrimitiveType.text, "text$arrayStr",
            isArray: isArray);
      case "integer":
      case "_int4":
        if (isArray) throw UnsupportedError("$this not supported as a type");
        return DataType(PrimitiveType.integer, "integer$arrayStr",
            isArray: isArray);
      case "smallint":
      case "_int2":
        if (isArray) throw UnsupportedError("$this not supported as a type");
        return DataType(PrimitiveType.smallInt, "smallInt$arrayStr",
            isArray: isArray);
      case "bigint":
      case "_int8":
        if (isArray) throw UnsupportedError("$this not supported as a type");
        return DataType(PrimitiveType.bigInt, "bigInt$arrayStr",
            isArray: isArray);
      case "boolean":
      case "_bool":
        if (isArray) throw UnsupportedError("$this not supported as a type");
        return DataType(PrimitiveType.boolean, "boolean$arrayStr",
            isArray: isArray);
      case "real":
      case "_float4":
        if (isArray) throw UnsupportedError("$this not supported as a type");
        return DataType(PrimitiveType.real, "real$arrayStr",
            isArray: isArray);
      case "date":
      case "_date":
        if (isArray) throw UnsupportedError("$this not supported as a type");
        return DataType(PrimitiveType.date, "date$arrayStr",
            isArray: isArray);
      case "oid":
      case "_oid":
        if (isArray) throw UnsupportedError("$this not supported as a type");
        return DataType(PrimitiveType.byteArray, "oid$arrayStr",
            isArray: isArray);
      case "ARRAY":
        return udtName.toDataType(udtName: udtName, isArray: true);
      default:
        throw UnsupportedError("$this not supported as a type");
    }
  }
}

// ignore: must_be_immutable
class PostgresClient extends DbClient<PostgreSQLConnection> {
  PostgresClient(DbConnectionParams params)
      : super(
          params,
          [
            PrimitiveType.text,
            PrimitiveType.varchar,
            PrimitiveType.integer,
            PrimitiveType.timestamp,
          ],
        );

  DataType toDataType({required String udtName, bool isArray = false}) {
    switch (udtName) {
      case "varchar":
      case "bpchar":
      case "char":
        return DataType(PrimitiveType.varchar, udtName, isArray: isArray);
      case "text":
        return DataType(PrimitiveType.text, udtName, isArray: isArray);
      case "int2":
        return DataType(PrimitiveType.smallInt, udtName, isArray: isArray);
      case "int4":
        return DataType(PrimitiveType.integer, udtName, isArray: isArray);
      case "int8":
        return DataType(PrimitiveType.bigInt, udtName, isArray: isArray);
      case "float4":
      case "float8":
      case "numeric":
        return DataType(PrimitiveType.real, udtName, isArray: isArray);
      case "bool":
        return DataType(PrimitiveType.boolean, udtName, isArray: isArray);
      case "timestamp":
        return DataType(PrimitiveType.timestamp, udtName, isArray: isArray);
      case "time":
        return DataType(PrimitiveType.time, udtName, isArray: isArray);
      case "date":
        return DataType(PrimitiveType.date, udtName, isArray: isArray);
      case "bytea":
        return DataType(PrimitiveType.byteArray, udtName, isArray: isArray);
      default:
        // Handle custom enum types as text
        return DataType(PrimitiveType.text, udtName, isArray: isArray);
    }
  }

  @override
  Future<PostgreSQLConnection> initConnection() async {
    debugPrint('Initializing PostgreSQL connection:');
    debugPrint('  Host: ${params.host}');
    debugPrint('  Port: ${params.port}');
    debugPrint('  Database: ${params.dbName}');
    debugPrint('  Username: ${params.username}');
    debugPrint('  SSL: ${params.useSSL}');

    return PostgreSQLConnection(
      params.host,
      params.port,
      params.dbName,
      username: params.username,
      password: params.password,
      useSSL: params.useSSL,
      timeoutInSeconds: 30,
      timeZone: 'UTC',
    );
  }

  @override
  Future<void> openConnection() async {
    try {
      debugPrint('Opening PostgreSQL connection...');
      await connection.open();
      debugPrint('Connection opened successfully');
    } catch (e, stackTrace) {
      debugPrint('Error opening PostgreSQL connection: $e');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  @override
  Future<void> closeConnection() async {
    await connection.close();
  }

  @override
  Future<void> _disconnect() async {
    await closeConnection();
  }

  @override
  Future<bool> checkConnection() async {
    final results = await connection.query("SELECT 1");
    return results.isNotEmpty;
  }

  @override
  Future<List<String>> getTables({bool verbose = false}) async {
    if (verbose) {
      debugPrint('Getting tables from PostgreSQL...');
    }

    final results = await connection.query(
      """
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      AND table_type = 'BASE TABLE'
      AND has_table_privilege(current_user, table_schema || '.' || table_name, 'SELECT')
      ORDER BY table_name
      """,
    );

    if (verbose) {
      debugPrint('Found ${results.length} tables:');
      for (final row in results) {
        debugPrint('- ${row[0]}');
      }
    }

    return List.generate(
      results.length,
      (i) => results[i][0] as String,
    );
  }

  @override
  Future<Set<Property>> getPropertiesFromTable(
    String table, {
    bool verbose = false,
  }) async {
    if (verbose) {
      debugPrint('Getting properties for table: $table');
    }

    try {
      final results = await connection.query(
        """
        SELECT column_name, 
               udt_name, 
               column_default, 
               is_nullable, 
               character_maximum_length, 
               ordinal_position,
               data_type
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = @table 
        ORDER BY ordinal_position
        """,
        substitutionValues: {
          "table": table,
        },
      );

      if (verbose) {
        debugPrint('Found ${results.length} columns for table $table:');
        for (final r in results) {
          debugPrint('- ${r[0]} (${r[1]}, ${r[6]})');
        }
      }

      final properties = <Property>{};
      for (final r in results) {
        try {
          final udtName = r[1] as String;
          final isArray = udtName.startsWith('_');
          final baseType = isArray ? udtName.substring(1) : udtName;

          properties.add(
            Property(
              r[5] as int,
              r[0] as String,
              toDataType(udtName: baseType, isArray: isArray),
              r[2],
              r[3] == 'YES',
              charMaxLength: r[4] as int?,
            ),
          );
        } catch (e) {
          debugPrint('Error processing column ${r[0]} in table $table: $e');
          rethrow;
        }
      }
      return properties;
    } catch (e) {
      debugPrint('Error getting properties for table $table: $e');
      rethrow;
    }
  }

  @override
  Future<void> getKeys() async {
    debugPrint("\n=== Getting Keys Debug ===");
    final results = await connection.query(
      """
      SELECT 
        tc.table_name, kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name,
        tc.constraint_type
      FROM information_schema.table_constraints AS tc 
      JOIN information_schema.key_column_usage AS kcu 
        ON tc.constraint_name = kcu.constraint_name 
        AND tc.table_schema = kcu.table_schema 
      LEFT JOIN information_schema.constraint_column_usage AS ccu 
        ON ccu.constraint_name = tc.constraint_name 
        AND ccu.table_schema = tc.table_schema 
      WHERE tc.table_schema = 'public' 
        AND (tc.constraint_type = 'PRIMARY KEY' 
        OR tc.constraint_type = 'FOREIGN KEY')
        AND tc.table_name = ANY(SELECT table_name 
                               FROM information_schema.tables 
                               WHERE table_schema = 'public' 
                               AND table_type = 'BASE TABLE')
      ORDER BY tc.table_name, tc.constraint_type DESC
      """,
    );

    debugPrint("Found ${results.length} key constraints");
    
    for (final result in results) {
      final tableName = result[0] as String;
      final columnName = result[1] as String;
      final foreignTableName = result[2] as String?;
      final constraintType = result[4] as String;
      
      debugPrint("\nProcessing constraint:");
      debugPrint("  Table: $tableName");
      debugPrint("  Column: $columnName");
      debugPrint("  Type: $constraintType");
      debugPrint("  Foreign Table: $foreignTableName");

      final tableQuery = tables.where((t) => t.name == tableName);
      
      if (tableQuery.isEmpty) {
        debugPrint('  Skipping keys for table not in set: $tableName');
        continue;
      }

      final table = tableQuery.first;
      debugPrint("  Found table in set: ${table.name}");
      
      try {
        if (constraintType == 'PRIMARY KEY') {
          debugPrint("  Processing primary key");
          final propertyQuery = table.properties.where((p) => p.name == columnName);
          if (propertyQuery.isEmpty) {
            debugPrint('  Primary key property not found: $columnName in $tableName');
            continue;
          }
          table.primaryKey = propertyQuery.first;
          debugPrint("  Set primary key: ${table.primaryKey?.name}");
        } else if (foreignTableName != null) {
          debugPrint("  Processing foreign key");
          final propertyQuery = table.properties.where((p) => p.name == columnName);
          if (propertyQuery.isEmpty) {
            debugPrint('  Foreign key property not found: $columnName in $tableName');
            continue;
          }
          final property = propertyQuery.first;
          
          final foreignTableQuery = tables.where((t) => t.name == foreignTableName);
          if (foreignTableQuery.isEmpty) {
            debugPrint('  Foreign key table not found: $foreignTableName');
            continue;
          }
          property.foreignKeyOf = foreignTableQuery.first;
          debugPrint("  Set foreign key reference: ${property.foreignKeyOf?.name}");
        }
      } catch (e) {
        debugPrint('  Error processing keys for table $tableName: $e');
        continue;
      }
    }
    
    debugPrint("\nFinal table keys status:");
    for (final table in tables) {
      debugPrint("Table ${table.name}:");
      debugPrint("  Primary Key: ${table.primaryKey?.name}");
      debugPrint("  Foreign Keys: ${table.properties.where((p) => p.foreignKeyOf != null).map((p) => '${p.name} -> ${p.foreignKeyOf?.name}').join(', ')}");
    }
    debugPrint("=======================\n");
  }

  @override
  Future<List<String>> getPkDistinctValues(
    app.Table table, {
    bool verbose = false,
    String? pattern,
  }) async {
    debugPrint("\n=== Autocomplete Debug ===");
    debugPrint("Table: ${table.name}");
    debugPrint("Primary Key: ${table.primaryKey?.name}");
    debugPrint("Search Pattern: $pattern");

    if (pattern == null || pattern.isEmpty || table.primaryKey == null) {
      debugPrint("Early return - Pattern is empty or no primary key");
      debugPrint("=======================\n");
      return [];
    }

    try {
      final tableName = dbStrFormat(table.name);
      final columnName = dbStrFormat(table.primaryKey!.name);
      final query = "SELECT DISTINCT $columnName "
          "FROM $tableName "
          "WHERE CAST($columnName AS TEXT) ILIKE @pattern "
          "ORDER BY $columnName "
          "LIMIT 10";
      
      debugPrint("SQL Query: $query");
      debugPrint("Pattern value: %$pattern%");

      final results = await connection.query(
        query,
        substitutionValues: {
          "pattern": "%$pattern%",
        },
      );

      debugPrint("Query results count: ${results.length}");
      debugPrint("Raw results: $results");
      
      final suggestions = results.map((row) => row[0].toString()).toList();
      debugPrint("Processed suggestions: $suggestions");
      debugPrint("=======================\n");
      
      return suggestions;
    } catch (e, stackTrace) {
      debugPrint("Error in getPkDistinctValues: $e");
      debugPrint("Stack trace: $stackTrace");
      debugPrint("=======================\n");
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
        return value is DateTime ? value : DateTime.parse(value.toString());
      case PrimitiveType.integer:
      case PrimitiveType.smallInt:
      case PrimitiveType.bigInt:
        return int.parse(value.toString());
      case PrimitiveType.real:
        return double.parse(value.toString());
      default:
        return value;
    }
  }

  @override
  Future<int> executeSQL(
    OpType opType,
    String command,
    List<dynamic> arguments,
  ) async {
    // Create a map of named parameters
    final substitutionValues = <String, dynamic>{};
    for (var i = 0; i < arguments.length; i++) {
      substitutionValues['arg$i'] = arguments[i];
    }
    
    debugPrint("Executing SQL with substitutions:");
    debugPrint("Command: $command");
    debugPrint("Values: $substitutionValues");
    
    final results = await connection.execute(
      command,
      substitutionValues: substitutionValues,
    );
    return results;
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
    // Replace ? placeholders with @argN parameters
    final parameterizedValues = values.split(',')
        .asMap()
        .entries
        .map((e) => '@arg${e.key}')
        .join(', ');
        
    return "INSERT INTO ${dbStrFormat(table.name)} ($properties) VALUES ($parameterizedValues)";
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