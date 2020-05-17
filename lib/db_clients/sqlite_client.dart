import 'package:bitacora/model/property.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:bitacora/utils/db_parameter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  static fromSQLiteValue(dynamic value, DataType type) {
    if (value.toString() == "") value = null;
    if (PrimitiveType.text == type.primitive && value != null)
      value = '''"${value.toString()}"''';
    return value.toString();
  }
}

// ignore: must_be_immutable
class SQLiteClient extends DbClient<Database> {
  SQLiteClient(DbConnectionParams params) : super(params);

  @override
  SvgPicture getLogo(Brightness brightness) => brightness == Brightness.light
      ? SvgPicture.asset('assets/images/SQLite.svg',
          height: 55, semanticsLabel: 'SQLite Logo')
      : SvgPicture.asset('assets/images/SQLite_dark.svg',
          height: 55, semanticsLabel: 'SQLite Logo');

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
      onCreate: (db, version) async {
        final batch = db.batch();
        batch.execute(
          "CREATE TABLE tutorial(hint TEXT, timestamp INTEGER)",
        );
        batch.insert("tutorial", {
          "hint":
              "Welcome! Select 'EDIT LAST FROM' to let me give you a few hints on how to use this app...\n\nCool, both actions are pretty self explanatory. Order criterion is defined in the data tab. Try removing this register by swiping the whole form.",
          "timestamp": 1445412480
        }); // Back to the future

        batch.insert("tutorial", {
          "hint":
              "Nice. That's pretty much it, now go connect with your DBs. Thanks for using Bitacora :)",
          "timestamp": 1345412480
        });

        batch.execute(
          "CREATE TABLE diary(description TEXT, time INTEGER)",
        ); // I wish many many people will download my app and give me lots of likes, that hurt... stop deleting...  please don't remove me... you really like deleting
        batch.execute(
          "CREATE TABLE quotes(quote TEXT, author TEXT, year INTEGER)",
        );
        await batch.commit(noResult: true);
      },
      version: 1,
    );
    isConnected = true;
    if (verbose)
      debugPrint("connect (${this.params.alias}): Connection established");
  }

  @override
  deleteLastFrom(app.Table table, {verbose = false}) async {
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
          var valueStr = SqLiteString.fromSQLiteValue(p.lastValue, p.type);
          return "${p.name} ${valueStr == "null" ? "is null" : "= $valueStr"}";
        }).join(" AND ");

    /// if orderBy is used
    String order =
        orderBy != null ? "ORDER BY ${orderBy.name} DESC" : "";

    String last =
        "SELECT ROWID FROM ${table.name} $where $order LIMIT 1";

    String sql = "DELETE FROM ${table.name} WHERE ROWID IN ($last)";

    if (verbose) debugPrint("removeLastEntry (${table.name}): $sql");

    var results = await connection.rawDelete(sql);
    if (results == 0) {
      throw Exception("Table is empty");
    }

    if (verbose) debugPrint("removeLastEntry (${table.name}): $results");
  }

  @override
  disconnect({verbose = false}) {
    return null;
  }

  @override
  editLastFrom(app.Table table, Map<Property, dynamic> propertiesForm,
      {verbose = false}) {
    return null;
  }

  @override
  getKeys({verbose = false}) {
    // TODO: implement getKeys
    return null;
  }

  @override
  getLastRow(app.Table table, {verbose = false}) async {
    Property orderBy = table.orderBy;
    if (orderBy == null) {
      if (verbose)
        debugPrint("getLastRow (${table.name}): No linearity defined");
      return;
    }

    var result = await connection.query(table.name,
        orderBy: "${orderBy.name} DESC", limit: 1);

    if (result.isNotEmpty) {
      for (final p in table.properties) {
        p.lastValue = result[0][p.name];
      }
    } else {
      table.properties.forEach((p) => p.lastValue = null);
    }
  }

  @override
  Future<List<String>> getPkDistinctValues(app.Table table,
      {verbose = false, String pattern}) {
    return null;
  }

  @override
  Future<Set<Property>> getPropertiesFromTable(String table,
      {verbose = false}) async {
    List res = await connection.rawQuery("PRAGMA table_info($table);");
    Set<Property> properties = Set();
    res.forEach((dict) => properties.add(Property(
        dict["cid"],
        dict["name"],
        dict["type"].toString().toDataType(),
        dict["dflt_value"],
        dict["notnull"] == 1 ? false : true)));
    return properties;
  }

  @override
  Future<List<String>> getTables({verbose = false}) async {
    List res = await connection.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name!='android_metadata'");
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
    return Future.value(true);
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

      /// if first time loading DB model identify the "ORDER BY field", since Postgres has a date and timestamp type
      if (this.tables == null) {
        var orderByCandidates = properties.where((property) => [
              PrimitiveType.integer,
              PrimitiveType.real,
            ].contains(property.type.primitive));
        if (orderByCandidates.length == 1)
          tables.last.orderBy = orderByCandidates.first;
      }

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
