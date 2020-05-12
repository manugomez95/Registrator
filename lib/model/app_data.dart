import 'package:bitacora/bloc/app_data/app_data_bloc.dart';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/db_clients/sqlite_client.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:bitacora/utils/db_parameter.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'action.dart' as app;

/// Singleton app controller
class AppData {
  // (https://github.com/felangel/bloc/issues/587)
  // ignore: close_sinks
  final AppDataBloc bloc = AppDataBloc();

  /// Runtime storage
  final Set<DbClient> dbs = Set();

  /// Persistence
  Future<SharedPreferences> sharedPrefs;
  Database localDb;

  Iterable<app.Table> getTables({bool onlyVisibles: true}) {
    return dbs
        .where((db) => db.isConnected)
        .map((DbClient db) => onlyVisibles
            ? db.tables?.where((table) => table.visible) ?? []
            : db.tables ?? [])
        ?.expand((i) => i);
  }

  // TODO [OFFLINE SUPPORT] make another table for each table with a queue of pending insertions (problem with autocomplete?)
  /// Local DB is composed of the following tables: connections and tables
  /// - tables: contain the orderBy and visibility configuration
  initLocalDb() async {
    localDb = await openDatabase(
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
            await SQLiteClient(DbConnectionParams("Demo", "localhost", 1234,
                    "demo.db", "", r"abracadabra", false))
                .toMap());

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

  saveConnection(DbClient dbClient) async {
    /// insert in connections
    await localDb.insert(
      'connections',
      await dbClient.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  saveTables(DbClient dbClient) async {
    /// for each table
    dbClient.tables.forEach((table) async {
      await localDb.insert(
        'tables',
        await table.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  removeConnection(DbClient dbClient) async {
    // Insert the Dog into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same dog is inserted twice.
    //
    // In this case, replace any previous data.
    await localDb.delete(
      'connections',
      // Use a `where` clause to delete a specific dog.
      where: "host = ? AND port = ? AND db_name = ?",
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: [
        dbClient.params.host,
        dbClient.params.port,
        dbClient.params.dbName
      ],
    );

    // TODO replace by id?
    await localDb.delete("tables",
        where: "host = ? AND port = ? AND db_name = ?",
        whereArgs: [
          dbClient.params.host,
          dbClient.params.port,
          dbClient.params.dbName
        ]);
  }

  checkLocalDataStatus() async {
    // Query the table for all The Dogs.
    print("Connections: ${await localDb.query('connections')}");
    print("Tables: ${await localDb.query('tables')}");
  }
}
