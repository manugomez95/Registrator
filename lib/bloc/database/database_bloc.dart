import 'dart:async';
import 'package:bitacora/bloc/app_data/app_data_event.dart';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/main.dart';
import 'package:bitacora/model/app_data.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:bloc/bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import './bloc.dart';
import 'package:flutter/material.dart';

// TODO starting to desmadrarse a bit
class DatabaseBloc extends Bloc<DatabaseEvent, DatabaseState> {
  @override
  DatabaseState get initialState => CheckingConnection();

  connectAndPull(DbClient dbClient,
      {bool fromForm: false}) async {
    try {
      await dbClient.connect();
      await dbClient.pullDatabaseModel(getLastRows: false);

      /// if not, we want to apply the saved user preferences to the table objects
      if (fromForm) {
        await getIt<AppData>().saveTables(dbClient);
      }
      else {
        await applySavedPreferences(dbClient);
      }

      /// get last row now that we have the saved orderBys
      for (var table in dbClient.tables) {
        await dbClient.getLastRow(table);
      }
      add(ConnectionSuccessfulEvent(dbClient));
    } on Exception catch (e) {
      add(ConnectionErrorEvent(e, dbClient));
    } on Error catch (e) {
      add(ConnectionErrorEvent(e, dbClient));
    }
  }

  /// specifically visibility and orderBy of table
  applySavedPreferences(DbClient dbClient) async {
    final List<Map<String, dynamic>> savedTables = await getIt<AppData>()
        .database
        .query('tables',
            where: "host = ? AND port = ? AND db_name = ?",
            whereArgs: [
          dbClient.params.host,
          dbClient.params.port,
          dbClient.params.dbName
        ]);

    for (final savedTable in savedTables) {
      app.Table t = dbClient.tables
          .firstWhere((t) => t.name == savedTable["name"], orElse: () => null);

      /// if table was deleted... then delete in local too
      if (t == null)
        await getIt<AppData>().database.delete("tables",
            where: "host = ? AND port = ? AND db_name = ? AND name = ?",
            whereArgs: [
              dbClient.params.host,
              dbClient.params.port,
              dbClient.params.dbName,
              savedTable["name"]
            ]);
      else {
        t.visible = savedTable["visible"] == 0 ? false : true;
        if (savedTable["order_by"] != null)
          t.orderBy = t.properties.firstWhere(
              (property) => property.name == savedTable["order_by"]);
      }
    }
  }

  @override
  Stream<DatabaseState> mapEventToState(
    DatabaseEvent event,
  ) async* {
    if (event is ConnectToDatabase) {
      /// if first time connection (connection from form) save it
      yield CheckingConnection();
      if (event.fromForm) {
        getIt<AppData>().dbs.add(event.dbClient);
        await getIt<AppData>().saveConnection(event.dbClient);
      }
      /// Connect and pull db model async to not block the event loop
      connectAndPull(event.dbClient,
          fromForm: event.fromForm);
      getIt<AppData>().bloc.add(LoadingEvent());
    } else if (event is ConnectionSuccessfulEvent) {
      yield ConnectionSuccessful();
      // TODO better way to know why UI was updated // same with loading etc
      getIt<AppData>().bloc.add(UpdateUIEvent());
    } else if (event is ConnectionErrorEvent) {
      if (event.dbClient.isConnected) await event.dbClient.disconnect();
      Fluttertoast.showToast(
          msg: "[${event.dbClient.params.alias}] ${event.exception.toString()}"
              .replaceAll("Exception: ", ""),
          toastLength: Toast.LENGTH_LONG);
      yield ConnectionError(event.exception);
      getIt<AppData>().bloc.add(UpdateUIEvent());
    } else if (event is RemoveConnection) {
      await event.dbClient.disconnect();
      getIt<AppData>().dbs.remove(event.dbClient);
      await getIt<AppData>().removeConnection(event.dbClient);
      await getIt<AppData>().checkLocalDataStatus();
      getIt<AppData>().bloc.add(UpdateUIEvent());
    } else if (event is UpdateDbStatus) {
      yield CheckingConnection();
      if (!await event.dbClient.ping())
        connectAndPull(event.dbClient);
      else {
        await event.dbClient.pullDatabaseModel(getLastRows: false);
        await applySavedPreferences(event.dbClient);

        /// get last row now that we have the saved orderBys
        for (var table in event.dbClient.tables) {
          await event.dbClient.getLastRow(table);
        }
        add(ConnectionSuccessfulEvent(event.dbClient));
      }
    }

    /// useful for general cases where we want to execute async code and then update the UI
    else if (event is UpdateUIAfter) {
      await event.code();
      getIt<AppData>().bloc.add(UpdateUIEvent());
    }
  }
}
