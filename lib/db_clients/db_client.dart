import 'package:bitacora/bloc/database/bloc.dart';
import 'package:bitacora/model/property.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sqflite/sqflite.dart';

/// Exceptions vs booleans: https://softwareengineering.stackexchange.com/questions/330824/function-returning-true-false-vs-void-when-succeeding-and-throwing-an-exception
/// The bottleneck in this functions is usually the network and I/O operations so we can afford to throw exceptions

enum OpType { insert, update, delete }

/// Why equatable?: To compare tables
// ignore: must_be_immutable
abstract class DbClient<T> extends Equatable {
  /// BLoC
  // ignore: close_sinks
  late final DatabaseBloc databaseBloc;

  /// Database model
  final DbConnectionParams params;
  late Set<app.Table> tables;
  final Duration timeout;
  final Duration queryTimeout;

  /// To autodetect orderBy candidates
  final List<PrimitiveType> orderByTypes;

  /// Connection
  T? _connection;
  bool isConnected = false;

  T get connection => _connection!;

  DbClient(
    this.params,
    this.orderByTypes, {
    this.timeout = const Duration(seconds: 3),
    this.queryTimeout = const Duration(seconds: 2),
  }) {
    databaseBloc = DatabaseBloc();
    tables = {};
  }

  Future<Map<String, dynamic>> toMap() async {
    return await params.toMap();
  }

  @override
  List<Object> get props => [
        params.host,
        params.port,
        params.username,
        params.dbName,
      ];

  Future<void> dispose() async {
    await disconnect(verbose: true);
    databaseBloc.close();
    _clearPreparedStatements();
  }

  void _clearPreparedStatements() {
    // Override in specific clients if needed
  }

  Future<void> _disconnect();

  SvgPicture getLogo(Brightness brightness);

  /// Allows connection with db (should be called async)
  Future<void> connect({bool verbose = false}) async {
    if (_connection == null) {
      _connection = await initConnection();
    }
    await openConnection();
    isConnected = true;
    if (verbose) {
      debugPrint("connect (${params.alias}): Connection established");
    }
  }

  @protected
  Future<T> initConnection();

  @protected
  Future<void> openConnection();

  Future<void> disconnect({bool verbose = false}) async {
    if (verbose) {
      print('Disconnecting from ${params.alias}...');
    }
    await _disconnect();
    isConnected = false;
  }

  @protected
  Future<void> closeConnection();

  Future<void> pullDatabaseModel({
    bool verbose = false,
    bool getLastRows = true,
  }) async {
    if (verbose) {
      debugPrint(
        "pullDatabaseModel (${params.alias}): ${tables.isEmpty ? 'Getting model for the first time' : 'Updating model'}",
      );
    }

    final tablesNames = await getTables(verbose: verbose);
    final newTables = <app.Table>{};

    for (final tName in tablesNames) {
      try {
        final properties = await getPropertiesFromTable(tName, verbose: verbose);
        final table = app.Table(tName, properties, this);
        newTables.add(table);

        if (tables.isEmpty) {
          final orderByCandidates = properties.where(
            (property) => orderByTypes.contains(property.type.primitive),
          );
          if (orderByCandidates.length == 1) {
            table.orderBy = orderByCandidates.first;
          }
        }

        await table.save(conflictAlgorithm: ConflictAlgorithm.ignore);

        if (getLastRows) {
          await getLastRow(table);
        }
      } on UnsupportedError catch (e) {
        if (verbose) debugPrint(e.toString());
        continue;
      }
    }

    tables = newTables;
    await getKeys();
  }

  @protected
  Future<List<String>> getTables({bool verbose = false});

  @protected
  Future<Set<Property>> getPropertiesFromTable(
    String table, {
    bool verbose = false,
  });

  /// Checks connection
  Future<bool> ping({bool verbose = false}) async {
    if (_connection == null) return false;
    try {
      await checkConnection().timeout(timeout);
      return isConnected;
    } on Exception catch (e) {
      if (verbose) {
        debugPrint("ping (${params.alias}): ${e.toString()}");
      }
      await disconnect();
      return false;
    }
  }

  @protected
  Future<bool> checkConnection();

  Future<void> getLastRow(app.Table table, {bool verbose = false}) async {
    final orderBy = table.orderBy;
    if (orderBy == null) {
      if (verbose) {
        debugPrint("getLastRow (${table.name}): No linearity defined");
      }
      return;
    }

    try {
      final results = await queryLastRow(
        table,
        orderBy,
        verbose: verbose,
      ).timeout(timeout);

      if (verbose) debugPrint("getLastRow: $results");

      if (results.isNotEmpty) {
        if (results.length != table.properties.length) {
          throw Exception("Results different than expected");
        }

        for (var i = 0; i < table.properties.length; i++) {
          final property = table.properties.elementAt(i);
          property.lastValue = resToValue(results[i], property.type);
        }
      } else {
        for (final property in table.properties) {
          property.lastValue = null;
        }
      }
    } on Exception catch (e) {
      if (verbose) debugPrint("getLastRow (${table.name}): $e");
    }
  }

  @protected
  Future<List<dynamic>> queryLastRow(
    app.Table table,
    Property orderBy, {
    bool verbose = false,
  });

  /// Convert database result to typed value
  @protected
  dynamic resToValue(dynamic res, DataType type);

  Future<bool> insertRowIntoTable(
    app.Table table,
    Map<Property, dynamic> propertiesForm, {
    bool verbose = false,
  }) async {
    final propertiesNames = propertiesForm.keys
        .map((Property p) => dbStrFormat(p.name))
        .join(", ");

    final qMarks = List.filled(propertiesForm.length, "?").join(", ");
    final command = insertSQL(table, propertiesNames, qMarks);
    
    final properties = table.properties.toList();
    final arguments = List.generate(
      propertiesForm.values.length,
      (i) => fromValueToDbValue(
        propertiesForm.values.toList()[i],
        properties[i].type,
      ),
    );

    if (verbose) {
      debugPrint("insertRowIntoTable (${table.name}): $command | $arguments");
    }

    try {
      final results = await executeSQL(OpType.insert, command, arguments);
      if (verbose) debugPrint("insertRowIntoTable: $results");
      
      if (results == 1) {
        for (final property in table.properties) {
          property.lastValue = propertiesForm[property];
        }
        return true;
      }
      return false;
    } on Exception catch (e) {
      if (verbose) debugPrint(e.toString());
      rethrow;
    }
  }

  @protected
  String insertSQL(app.Table table, String properties, String values);

  @protected
  String dbStrFormat(String str);

  @protected
  dynamic fromValueToDbValue(dynamic value, DataType type);

  @protected
  Future<int> executeSQL(OpType opType, String command, List<dynamic> arguments);

  @protected
  Future<void> getKeys();

  Future<bool> editLastFrom(app.Table table, Map<Property, dynamic> propertiesForm) async {
    final command = editLastFromSQL(table);
    final arguments = table.properties
        .map((p) => fromValueToDbValue(propertiesForm[p], p.type))
        .toList();
    
    try {
      final results = await executeSQL(OpType.update, command, arguments);
      return results > 0;
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  Future<bool> deleteLastFrom(app.Table table) async {
    final command = deleteLastFromSQL(table);
    final arguments = table.properties
        .where((p) => p.lastValue != null)
        .map((p) => fromValueToDbValue(p.lastValue, p.type))
        .toList();
    
    try {
      final results = await executeSQL(OpType.delete, command, arguments);
      return results > 0;
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  @protected
  String editLastFromSQL(app.Table table);

  @protected
  String deleteLastFromSQL(app.Table table);
}
