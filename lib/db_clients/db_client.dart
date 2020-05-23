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
  DatabaseBloc databaseBloc;

  /// Database model
  DbConnectionParams params;
  Set<app.Table> tables;
  final Duration timeout; // TODO make private?
  final Duration queryTimeout; // TODO make private?

  /// To autodectect orderBy candidates
  final List<PrimitiveType> orderByTypes;

  /// Connection
  @protected
  T connection;
  bool isConnected = false;

  DbClient(this.params, this.orderByTypes,
      {this.timeout: const Duration(seconds: 3),
      this.queryTimeout: const Duration(seconds: 2)}) {
    databaseBloc = DatabaseBloc();
  }

  Future<Map<String, dynamic>> toMap() async {
    return await params.toMap();
  }

  @override
  List<Object> get props => [
        this.params.host,
        this.params.port,
        this.params.username,
        this.params.dbName
      ];

  SvgPicture getLogo(Brightness brightness);

  /// Allows connection with db (should be called async)
  connect({verbose: false}) async {
    if (connection == null) connection = await initConnection();
    await openConnection();
    isConnected = true;
    if (verbose)
      debugPrint("connect (${this.params.alias}): Connection established");
  }

  @protected
  Future<T> initConnection();
  @protected
  openConnection();

  disconnect({verbose: false}) async {
    await closeConnection();
    connection = null;
    isConnected = false;
    if (verbose) debugPrint("disconnect (${this.params.alias})");
  }

  @protected
  closeConnection();

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

    // TODO [future] get user defined types (for enum)

    /// For each table:
    Set<app.Table> tables = Set();
    for (var tName in tablesNames) {
      /// get properties...
      try {
        Set<Property> properties =
            await getPropertiesFromTable(tName, verbose: verbose);

        tables.add(app.Table(tName, properties, this));

        /// if first time loading DB model identify the "ORDER BY field", since Postgres has a date and timestamp type
        if (this.tables == null) {
          var orderByCandidates = properties.where(
              (property) => orderByTypes.contains(property.type.primitive));
          if (orderByCandidates.length == 1)
            tables.last.orderBy = orderByCandidates.first;
        }

        /// Save table information in local SQLite
        await tables.last.save(conflictAlgorithm: ConflictAlgorithm.ignore);
      } on UnsupportedError catch (e) {
        if (verbose) debugPrint(e.toString());
        continue;
        // TODO mark table with Unsupported label? Show toast or something
      }

      /// and [optionally] get last row
      if (getLastRows) await getLastRow(tables.last);
    }

    this.tables = tables;

    /// get foreign and primary keys info
    await getKeys();
  }

  /// Returns list of table names
  @protected
  Future<List<String>> getTables({verbose: false});
  @protected
  Future<Set<Property>> getPropertiesFromTable(String table, {verbose: false});

  /// Checks connection
  Future<bool> ping({verbose: false}) async {
    if (connection == null) return false;
    try {
      await checkConnection().timeout(timeout);
    } on Exception catch (e) {
      if (verbose) debugPrint("ping (${this.params.alias}): ${e.toString()}");
      await disconnect();
    } finally {
      // ignore: control_flow_in_finally
      return isConnected;
    }
  }

  @protected
  Future<bool> checkConnection();

  /// updates last values based on OrderBy
  getLastRow(app.Table table, {verbose: false}) async {
    Property orderBy = table.orderBy;
    if (orderBy == null) {
      if (verbose)
        debugPrint("getLastRow (${table.name}): No linearity defined");
      return;
    }

    List<dynamic> results = [];
    try {
      results =
          await queryLastRow(table, orderBy, verbose: verbose).timeout(timeout);

      if (verbose) debugPrint("getLastRow: $results");
    } on Exception catch (e) {
      if (verbose) debugPrint("getLastRow (${table.name}): $e");
    } on Error catch (e) {
      if (verbose) debugPrint("getLastRow (${table.name}): $e");
    }

    if (results.isNotEmpty) {
      var i = 0;
      if (results.length != table.properties.length)
        throw Exception("Results different than expected");
      for (final p in table.properties) {
        /// Why not use saved index position instead of i? Because index position might not make much sense (after fields have been deleted for example)
        p.lastValue = resToValue(results[i], p.type);
        i++;
      }
    } else {
      table.properties.forEach((p) => p.lastValue = null);
    }
  }

  @protected
  Future<List<dynamic>> queryLastRow(app.Table table, Property orderBy,
      {verbose: false});
  @protected

  /// result of querying table -> value
  dynamic resToValue(dynamic res, DataType type);

  /// inserts and updates last values
  insertRowIntoTable(app.Table table, Map<Property, dynamic> propertiesForm,
      {verbose: true}) async {
    String propertiesNames =
        propertiesForm.keys.map((Property p) => dbStrFormat(p.name)).join(", ");

    String qMarks = List.filled(propertiesForm.length, "?").join(", ");

    String command = insertSQL(table, propertiesNames, qMarks);
    List<Property> properties = table.properties.toList();
    List arguments = List.generate(
        propertiesForm.values.length,
        (i) => fromValueToDbValue(
            propertiesForm.values.toList()[i], properties[i].type));

    if (verbose) debugPrint("insertRowIntoTable (${table.name}): $command | $arguments");

    try {
      var results = await executeSQL(OpType.insert, command, arguments);
      if (verbose) debugPrint("insertRowIntoTable: $results");
      if (results == 1) {
        /// Update official last row
        table.properties.forEach((p) => p.lastValue = propertiesForm[p]);
        return true;
      } else
        return false;
    } on Exception catch (e) {
      if (verbose) debugPrint(e.toString());
      throw e;
    }
  }

  @protected
  insertSQL(app.Table table, String properties, String values);

  /// Always use last values, forget about order because last values depend on order
  editLastFrom(app.Table table, Map<Property, dynamic> propertiesForm,
      {verbose: false}) async {
    /// if there's no last values...
    if (table.properties.every((p) => p.lastValue == null)) {
      throw Exception("No last values");
    }

    /// this are the new values
    List newValues = propertiesForm.keys
        .map((p) => fromValueToDbValue(propertiesForm[p], p.type))
        .toList();

    var sql = editLastFromSQL(table);

    var oldValues = table.properties
        .where((p) => p.lastValue != null)
        .map((p) => fromValueToDbValue(p.lastValue, p.type))
        .toList();
    if (verbose) debugPrint("editLastFrom (${table.name}): $sql | $oldValues");

    try {
      var results = await executeSQL(
          OpType.update, sql, newValues.followedBy(oldValues).toList());
      debugPrint("editLastFrom (${table.name}): $results");
      if (results == 1) {
        /// Update official last row
        table.properties.forEach((p) => p.lastValue = propertiesForm[p]);
        return true;
      } else
        return false;
    } on Exception catch (e) {
      if (verbose) debugPrint("editLastFrom (${table.name}): ${e.toString()}");
      throw e;
    }
  }

  @protected
  String editLastFromSQL(app.Table table);

  /// Always use last values, forget about order because last values depend on order
  deleteLastFrom(app.Table table, {verbose: false}) async {
    /// if there's no last values...
    if (table.properties.every((p) => p.lastValue == null)) {
      throw Exception("No last values");
    }

    var sql = deleteLastFromSQL(table);
    var arguments = table.properties
        .where((p) => p.lastValue != null)
        .map((p) => fromValueToDbValue(p.lastValue, p.type))
        .toList();
    if (verbose)
      debugPrint("removeLastEntry (${table.name}): $sql | $arguments");

    try {
      /// ...so, we only include as arguments the non null values
      var results = await executeSQL(OpType.delete, sql, arguments);
      if (verbose) debugPrint("removeLastEntry (${table.name}): $results");

      // TODO necessary, there's a first check at the begining
      if (results == 0) {
        throw Exception("Table is empty");
      }
    } on Exception catch (e) {
      if (verbose)
        debugPrint("removeLastEntry (${table.name}): ${e.toString()}");
      throw e;
    }
  }

  @protected
  String deleteLastFromSQL(app.Table table);

  /// Table properties need to be already created and also the rest of the tables
  getKeys({verbose: false});

  Future<List<String>> getPkDistinctValues(app.Table table,
      {verbose: false, String pattern});

  /// ------------ SQL helpers -------------------
  /// ? are replaced by arguments
  /// return number of rows affected
  Future<int> executeSQL(OpType opType, String command, List arguments);

  query(String command, List arguments);

  /// ----------- STRING related ------------- TODO move to another class?

  /// properties form value -> str of insert order
  fromValueToDbValue(dynamic value, DataType type, {bool fromArray: false});

  String dbStrFormat(String str);
}
