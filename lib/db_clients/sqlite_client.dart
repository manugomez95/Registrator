import 'package:bitacora/bloc/database/database_event.dart';
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
    try {
      connection = await openDatabase(
        join(await getDatabasesPath(), 'demo.db'),
        // When the database is first created, create a table to store app data.
        onCreate: (db, version) {
          // Run the CREATE TABLE statement on the database.
          return db.execute(
            "CREATE TABLE connections(alias TEXT, host TEXT, port INTEGER, db_name TEXT, username TEXT, password TEXT, ssl INTEGER)",
          );
        },
        // Set the version. This executes the onCreate function and provides a
        // path to perform database upgrades and downgrades.
        version: 1,
      );

      if (verbose)
        debugPrint(
            "[1/2] connect (${this.params.alias}): Connection established");
      await pullDatabaseModel();
      if (verbose)
        debugPrint("[2/2] connect (${this.params.alias}): DB model updated");
      isConnected = true;
      return true;
    } on Exception catch (e) {
      if (verbose)
        debugPrint("connect (${this.params.alias}): ${e.toString()}");
      await disconnect();
      databaseBloc.add(ConnectionErrorEvent(e));
      return false;
    }
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
  ping({verbose = false}) {
    // TODO: implement ping
    return null;
  }

  @override
  // TODO: implement props
  List<Object> get props => null;

  @override
  pullDatabaseModel({verbose = false}) {
    // TODO: implement updateDatabaseModel
    return null;
  }

  @override
  setConnectionParams(DbConnectionParams params, {verbose}) {
    // TODO: implement setConnectionParams
    return null;
  }
}
