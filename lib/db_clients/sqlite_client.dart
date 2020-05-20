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
  SQLiteClient._(DbConnectionParams params, List<PrimitiveType> orderByTypes)
      : super(params, orderByTypes);

  factory SQLiteClient(DbConnectionParams params) {
    List<PrimitiveType> orderByTypes = [
      PrimitiveType.integer,
      PrimitiveType.real,
    ];
    return SQLiteClient._(params, orderByTypes);
  }

  @override
  Future<Map<String, dynamic>> toMap() async {
    Map<String, dynamic> params = await super.toMap();
    params["brand"] = "sqlite_android";
    return params;
  }

  @override
  SvgPicture getLogo(Brightness brightness) => brightness == Brightness.light
      ? SvgPicture.asset('assets/images/SQLite.svg',
          height: 55, semanticsLabel: 'SQLite Logo')
      : SvgPicture.asset('assets/images/SQLite_dark.svg',
          height: 55, semanticsLabel: 'SQLite Logo');

  @override
  Future<Database> initConnection() async {
    return await openDatabase(
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
          "CREATE TABLE quotes(quote TEXT, author TEXT, year INTEGER)",
        );

        batch.insert("quotes", {
          "quote":
              "If you're going to try, go all the way. Otherwise, don't even start. This could mean losing girlfriends, wives, relatives and maybe even your mind. It could mean not eating for three or four days. It could mean freezing on a park bench. It could mean jail. It could mean derision. It could mean mockery--isolation. Isolation is the gift. All the others are a test of your endurance, of how much you really want to do it. And, you'll do it, despite rejection and the worst odds. And it will be better than anything else you can imagine. If you're going to try, go all the way. There is no other feeling like that. You will be alone with the gods, and the nights will flame with fire. You will ride life straight to perfect laughter. It's the only good fight there is.",
          "author": "Charles Bukowski",
          "year": 1975
        });

        await batch.commit(noResult: true);
      },
      version: 1,
    );
  }

  @override
  openConnection() {}

  @override
  closeConnection() {}

  @override
  Future<List<String>> getTables({verbose = false}) async {
    List res = await connection.query("sqlite_master",
        where: "type = ? AND name != ?",
        whereArgs: ["table", "android_metadata"]);
    return List<String>.generate(res.length, (i) {
      return res[i]["name"];
    });
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
  Future<bool> ping({verbose = false}) async {
    return true;
  }

  @override
  Future<bool> checkConnection() async {
    return true;
  }

  @override
  Future<List> queryLastRow(app.Table table, Property orderBy,
      {verbose = false}) async {
    return (await connection.query(table.name,
            orderBy: "${orderBy.name} DESC", limit: 1))
        .first
        .values
        .toList();
  }

  @override
  dynamic resToValue(dynamic res, DataType type) {
    return res;
  }

  @override
  insertSQL(app.Table table, String properties, String values) {
    return "INSERT INTO ${dbStrFormat(table.name)} ($properties) VALUES ($values)";
  }

  @override
  Future<int> executeCancelLastInsertion(app.Table table, String whereString,
      {verbose = false}) async {
    var sql =
        "DELETE FROM ${dbStrFormat(table.name)} WHERE ROWID IN (SELECT ROWID FROM ${dbStrFormat(table.name)} WHERE $whereString LIMIT 1)";
    if (verbose) debugPrint(sql);
    int id = await connection.rawInsert(sql);
    return 1;
  }

  @override
  String editLastFromSQL(app.Table table) {
    /// last values, IMPORTANT, when null there's no question mark so...
    String where = "WHERE " +
        table.properties.map((Property p) {
          return "${dbStrFormat(p.name)} ${p.lastValue == null ? "is null" : "= ?"}";
        }).join(" AND ");

    String propertiesNames = table.properties.map((e) => dbStrFormat(e.name)).join(", ");
    String valuesString = List.filled(table.properties.length, "?").join(", ");

    String last =
        "SELECT ROWID FROM ${dbStrFormat(table.name)} $where LIMIT 1";

    return "UPDATE ${table.name} SET ($propertiesNames) = ($valuesString) WHERE ROWID IN ($last)";
  }

  @override
  getKeys({verbose = false}) {}

  @override
  Future<List<String>> getPkDistinctValues(app.Table table,
      {verbose = false, String pattern}) {
    return null;
  }

  @override
  fromValueToDbValue(value, DataType type, {bool fromArray: false, bool inWhere: false}) {
    /// IMPORTANT
    if (value == null || value.toString() == "")
      return 'null';
    return value;
  }

  @override
  String dbStrFormat(String str) {
    return str;
  }

  // TODO return number of rows affected or 1 at least
  @override
  Future<int> executeSQL(OpType opType, String command, List arguments) {
    switch (opType) {
      case OpType.insert:
        return connection.rawInsert(command, arguments);
        break;
      case OpType.update:
        return connection.rawUpdate(command, arguments);
        break;
      case OpType.delete:
        return connection.rawDelete(command, arguments);
        break;
      default:
    }
  }

  @override
  query(String command, List arguments) {
    return connection.rawQuery(command, arguments);
  }

  @override
  String deleteLastFromSQL(app.Table table) {
    /// last values, IMPORTANT, when null there's no question mark so...
    String where = "WHERE " +
        table.properties.map((Property p) {
          return "${dbStrFormat(p.name)} ${p.lastValue == null ? "is null" : "= ?"}";
        }).join(" AND ");

    return "DELETE FROM ${dbStrFormat(table.name)} WHERE ROWID IN "
        "(SELECT ROWID FROM ${dbStrFormat(table.name)} $where LIMIT 1)";
  }
}
