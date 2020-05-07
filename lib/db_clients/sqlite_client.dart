import 'package:bitacora/model/property.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:bitacora/utils/db_parameter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'db_client.dart';

extension SqLiteString on String {
  DataType toDataType() {
    switch (this) {
      case "TEXT":
        return DataType(PrimitiveType.text, "text");
      case "INTEGER":
        return DataType(PrimitiveType.integer, "integer");
      case "REAL":
        return DataType(PrimitiveType.real, "real");
      default:
        throw UnsupportedError("$this not supported as a type");
    }
  }
}

// ignore: must_be_immutable
class SQLiteClient extends DbClient<Database> {
  SQLiteClient(DbConnectionParams params) : super(params);

  Widget logo = Container(
  child: SvgPicture.asset(
      'assets/images/SQLite.svg',
      height: 55,
      semanticsLabel: 'Postgres Logo'),
  width: 75,
  height: 75,);

  @override
  cancelLastInsertion(app.Table table, Map<Property, dynamic> propertiesForm,
      {verbose = false}) {
    // TODO: implement cancelLastInsertion
    return null;
  }

  @override
  Future<Map<String, dynamic>> toMap() async {
    Map<String, dynamic> params = await super.toMap();
    params["brand"] = "sqlite_android";
    return params;
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
      {verbose = false}) async {
    List res = await connection.rawQuery("PRAGMA table_info($table);");
    Set<Property> properties = Set();
    res.forEach((dict) => properties.add(Property(dict["cid"], dict["name"], dict["type"].toString().toDataType(), dict["dflt_value"], dict["notnull"] == 1 ? false : true)));
    return properties;
  }

  @override
  Future<List<String>> getTables({verbose = false}) async {
    List res = await connection.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name!='android_metadata'");
    return List<String>.generate(res.length, (i) {
      return res[i]["name"];
    });
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
      await tables.last.save(conflictAlgorithm: ConflictAlgorithm.ignore);
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
