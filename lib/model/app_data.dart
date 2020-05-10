import 'package:bitacora/bloc/app_data/app_data_bloc.dart';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/db_clients/sqlite_client.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:bitacora/utils/db_parameter.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'action.dart' as app;

class AppData {
  // ignore: close_sinks
  final AppDataBloc bloc = AppDataBloc();

  final Set<DbClient> dbs = Set();
  Future<SharedPreferences> sharedPrefs;

  Database database;

  Iterable<DbClient> getDbs() {
    return dbs.where((db) => db.isConnected);
  }

  Iterable<app.Table> getTables({bool onlyVisibles: true}) {
    return getDbs()
        .map((DbClient db) => onlyVisibles
            ? db.tables?.where((table) => table.visible) ?? []
            : db.tables ?? [])
        ?.expand((i) => i);
  }

  initializeLocalDb() async {
    bool firstTime = false;
    database = await openDatabase(
      // Set the path to the database.
      join(await getDatabasesPath(), 'app_data.db'),
      // When the database is first created, create a table to store app data.
      onCreate: (db, version) async {
        // TODO substitute by batch
        await db.execute(
          "CREATE TABLE connections(brand TEXT, alias TEXT, host TEXT, port INTEGER, db_name TEXT, username TEXT, password TEXT, ssl INTEGER, PRIMARY KEY (host, port, db_name))",
        );

        // TODO end up removing this part
        await db.insert(
            "connections",
            await SQLiteClient(DbConnectionParams("Demo", "localhost", 1234,
                "demo.db", "", r"abracadabra", false))
                .toMap());
        await db.execute(
            "CREATE TABLE tables(name TEXT, primary_key TEXT, order_by TEXT, visible INTEGER, host TEXT, port INTEGER, db_name TEXT, PRIMARY KEY (name, host, port, db_name))");
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
  }

  saveConnection(DbClient dbClient) async {
    /// insert in connections
    await database.insert(
      'connections',
      await dbClient.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  saveTables(DbClient dbClient) async {
    /// for each table
    dbClient.tables.forEach((table) async {
      await database.insert(
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
    await database.delete(
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
    await database.delete("tables",
        where: "host = ? AND port = ? AND db_name = ?",
        whereArgs: [
          dbClient.params.host,
          dbClient.params.port,
          dbClient.params.dbName
        ]);
  }

  checkLocalDataStatus() async {
    // Query the table for all The Dogs.
    print("Connections: ${await database.query('connections')}");
    print("Tables: ${await database.query('tables')}");
  }
}
