import 'package:bitacora/model/property.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:bitacora/utils/db_parameter.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'db_client.dart';

// ignore: must_be_immutable
class SQLiteClient extends DbClient<Database> {
  SQLiteClient(DbConnectionParams params) : super(params);

  @override
  cancelLastInsertion(app.Table table, Map<Property, dynamic> propertiesForm,
      {verbose = false}) {
    // TODO: implement cancelLastInsertion
    return null;
  }

  @override
  connect({verbose: false, fromForm: false}) async {
    connection = await openDatabase(
      join(await getDatabasesPath(), 'demo.db'),
      // When the database is first created, create a table to store app data.
      onCreate: (db, version) async {
        // Run the CREATE TABLE statement on the database.
        await db.execute(
          "CREATE TABLE training(type TEXT, reps INTEGER, weight INTEGER, date_time TEXT)",
        );
        await db.execute(
          "CREATE TABLE ufos(description TEXT, time INTEGER)",
        );
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
    isConnected = true;
    if (verbose)
      debugPrint("connect (${this.params.alias}): Connection established");
  }

  @override
  deleteLastFrom(app.Table table, {verbose = false}) {
    // TODO: implement deleteLastFrom
    return null;
  }

  @override
  disconnect({verbose = false}) {
    // TODO: implement disconnect
    return null;
  }

  @override
  editLastFrom(app.Table table, Map<Property, dynamic> propertiesForm,
      {verbose = false}) {
    // TODO: implement editLastFrom
    return null;
  }

  @override
  getKeys({verbose = false}) {
    // TODO: implement getKeys
    return null;
  }

  @override
  getLastRow(app.Table table, {verbose = false}) {
    // TODO: implement getLastRow
    return null;
  }

  @override
  Future<List<String>> getPkDistinctValues(app.Table table,
      {verbose = false, String pattern}) {
    // TODO: implement getPkDistinctValues
    return null;
  }

  @override
  Future<Set<Property>> getPropertiesFromTable(String table,
      {verbose = false}) {
    // TODO: implement getPropertiesFromTable
    return null;
  }

  @override
  Future<List<String>> getTables({verbose = false}) {
    // TODO: implement getTables
    return null;
  }

  @override
  insertRowIntoTable(app.Table table, Map<Property, dynamic> propertiesForm,
      {verbose = false}) {
    // TODO: implement insertRowIntoTable
    return null;
  }

  @override
  Future<bool> ping({verbose = false}) async {
    return true;
  }

  @override
  pullDatabaseModel({verbose: false, getLastRows: true}) async {
    /// Get tables
    List<String> tablesNames = await getTables(verbose: verbose);

    /// For each table:
    Set<app.Table> tables = Set();
    for (var tName in tablesNames) {
      /// get properties...
      Set<Property> properties = await getPropertiesFromTable(tName);

      tables.add(app.Table(tName, properties, this));

      /// if first time loading DB model identify the "ORDER BY field"...
      if (this.tables == null) {
        var orderByCandidates = properties.where((property) => [
          PrimitiveType.date,
          PrimitiveType.timestamp,
        ].contains(property.type.primitive));
        if (orderByCandidates.length == 1)
          tables.last.orderBy = orderByCandidates.first;
      }

      /// [optionally] and get last row
      if (getLastRows) await getLastRow(tables.last);
    }

    this.tables = tables;

    /// get foreign and primary keys info
    await getKeys();
  }

  @override
  setConnectionParams(DbConnectionParams params, {verbose}) {
    // TODO: implement setConnectionParams
    return null;
  }
}
