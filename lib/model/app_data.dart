import 'package:bitacora/bloc/app_data/app_data_bloc.dart';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:path/path.dart';
import 'package:pointycastle/api.dart';
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
    return dbs.where((db) => db.isConnected).toList();
  }

  Iterable<app.Table> getTables({bool onlyVisibles: true}) {
    return getDbs()
        .map((DbClient db) => onlyVisibles
            ? db.tables?.where((table) => table.visible) ?? []
            : db.tables ?? [])
        ?.expand((i) => i)
        ?.toList();
  }

  initializeLocalDb() async {
    database = await openDatabase(
      // Set the path to the database.
      join(await getDatabasesPath(), 'app_data.db'),
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
  }

  saveConnection(DbClient dbClient) async {
    // Insert the Dog into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same dog is inserted twice.
    //
    // In this case, replace any previous data.
    await database.insert(
      'connections',
      await dbClient.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
      whereArgs: [dbClient.params.host, dbClient.params.port, dbClient.params.dbName],
    );
  }

  // A method that retrieves all the dogs from the dogs table.
  Future<List<Map<String, dynamic>>> connections() async {
    // Query the table for all The Dogs.
    final List<Map<String, dynamic>> maps = await database.query('connections');

    // Convert the List<Map<String, dynamic> into a List<Dog>.
    return maps;
  }
}
