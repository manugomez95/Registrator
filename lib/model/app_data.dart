import 'package:bitacora/bloc/app_data/app_data_bloc.dart';
import 'package:bitacora/db_clients/bigquery_client.dart';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/db_clients/sqlite_client.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:bitacora/utils/db_parameter.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'action.dart' as app;
import 'package:flutter/material.dart';

/// Singleton app controller
class AppData {
  // (https://github.com/felangel/bloc/issues/587)
  // ignore: close_sinks
  final AppDataBloc bloc = AppDataBloc();

  /// Runtime storage
  final Set<DbClient> dbs = {};

  /// Persistence
  late Future<SharedPreferences> _sharedPrefs;
  Database? _localDb;

  Future<SharedPreferences> get sharedPrefs => _sharedPrefs;
  Database get localDb => _localDb!;

  void initSharedPrefs() {
    _sharedPrefs = SharedPreferences.getInstance();
  }

  Iterable<app.Table> getTables({bool onlyVisibles = true}) {
    return dbs
        .where((db) => db.isConnected)
        .expand((db) => onlyVisibles
            ? db.tables.where((table) => table.visible)
            : db.tables);
  }

  bool updateForm = false;

  /// Local DB is composed of the following tables: connections and tables
  /// - tables: contain the orderBy and visibility configuration
  Future<void> initLocalDb() async {
    _localDb = await openDatabase(
      join(await getDatabasesPath(), 'app_data.db'),
      onCreate: (db, version) async {
        final batch = db.batch();
        batch.execute(
          "CREATE TABLE connections("
          "brand TEXT, "
          "alias TEXT, "
          "host TEXT, "
          "port INTEGER, "
          "db_name TEXT, "
          "username TEXT, "
          "password TEXT, "
          "ssl INTEGER, "
          "PRIMARY KEY (host, port, db_name))",
        );

        /// Here we define the demo connection
        batch.insert(
            "connections",
            await SQLiteClient(DbConnectionParams(
              'Local DB',
              'local',
              0,
              'bitacora.db',
              '',
              '',
              false,
              'sqlite',
            )).toMap());

        batch.execute(
            "CREATE TABLE tables("
            "name TEXT, "
            "primary_key TEXT, "
            "order_by TEXT, "
            "visible INTEGER, "
            "host TEXT, "
            "port INTEGER, "
            "db_name TEXT, "
            "PRIMARY KEY (name, host, port, db_name))");

        await batch.commit(noResult: true);
      },
      version: 1,
    );
  }

  Future<void> saveConnection(DbClient dbClient) async {
    await localDb.insert(
      'connections',
      await dbClient.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveTables(DbClient dbClient) async {
    for (final table in dbClient.tables) {
      await localDb.insert(
        'tables',
        await table.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> removeConnection(DbClient dbClient) async {
    await localDb.delete(
      'connections',
      where: "host = ? AND port = ? AND db_name = ?",
      whereArgs: [
        dbClient.params.host,
        dbClient.params.port,
        dbClient.params.dbName
      ],
    );

    await localDb.delete(
      "tables",
      where: "host = ? AND port = ? AND db_name = ?",
      whereArgs: [
        dbClient.params.host,
        dbClient.params.port,
        dbClient.params.dbName
      ],
    );
  }

  Future<void> checkLocalDataStatus() async {
    final connections = await localDb.query('connections');
    final tables = await localDb.query('tables');
    debugPrint("Connections: $connections");
    debugPrint("Tables: $tables");
  }

  List<app.Action> get actions => [
        app.Action(
          app.ActionType.insertInto,
          'Insert Into',
          Icons.add,
          Colors.green,
        ),
        app.Action(
          app.ActionType.editLastFrom,
          'Edit Last From',
          Icons.edit,
          Colors.blue,
        ),
        app.Action(
          app.ActionType.deleteLastFrom,
          'Delete Last From',
          Icons.delete,
          Colors.red,
        ),
      ];

  void dispose() {
    bloc.close();
    for (final db in dbs) {
      db.dispose();
    }
  }
}
