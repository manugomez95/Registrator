import 'dart:async';
import 'package:bitacora/bloc/app_data/app_data_event.dart';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/main.dart';
import 'package:bitacora/model/app_data.dart';
import 'package:bitacora/model/property.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import './bloc.dart';

/// Handles the individual database events and states
class DatabaseBloc extends Bloc<DatabaseEvent, DatabaseState> {
  DatabaseBloc() : super(CheckingConnection()) {
    on<ConnectToDatabase>(_onConnectToDatabase);
    on<ConnectionSuccessfulEvent>(_onConnectionSuccessful);
    on<ConnectionErrorEvent>(_onConnectionError);
    on<RemoveConnection>(_onRemoveConnection);
    on<UpdateDbStatus>(_onUpdateDbStatus);
    on<UpdateUIAfter>(_onUpdateUIAfter);
  }

  Future<void> _onConnectToDatabase(
    ConnectToDatabase event,
    Emitter<DatabaseState> emit,
  ) async {
    emit(CheckingConnection());

    try {
      // Connect and pull data in the background
      await event.dbClient.connect(verbose: true);
      await event.dbClient.pullDatabaseModel();
      await getIt<AppData>().saveTables(event.dbClient);
      
      // Update AppData state to notify UI
      getIt<AppData>().updateDatabaseState(event.dbClient);
      
      add(ConnectionSuccessfulEvent(event.dbClient));

      // Show success message
      Fluttertoast.showToast(
        msg: "Successfully connected to ${event.dbClient.params.alias}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50), // Material Green
      );
    } catch (e, stackTrace) {
      debugPrint('Error connecting to database: $e');
      debugPrint(stackTrace.toString());
      add(ConnectionErrorEvent(e, event.dbClient));
    }
  }

  Future<void> _onConnectionSuccessful(
    ConnectionSuccessfulEvent event,
    Emitter<DatabaseState> emit,
  ) async {
    emit(ConnectionSuccessful());
    getIt<AppData>().bloc.add(UpdateUIEvent());
  }

  Future<void> _onConnectionError(
    ConnectionErrorEvent event,
    Emitter<DatabaseState> emit,
  ) async {
    if (event.dbClient.isConnected) {
      await event.dbClient.disconnect();
    }
    
    Fluttertoast.showToast(
      msg: "[${event.dbClient.params.alias}] ${event.exception.toString()}"
          .replaceAll("Exception: ", ""),
      toastLength: Toast.LENGTH_LONG,
    );
    
    emit(ConnectionError(event.exception));
    getIt<AppData>().bloc.add(UpdateUIEvent());
  }

  Future<void> _onRemoveConnection(
    RemoveConnection event,
    Emitter<DatabaseState> emit,
  ) async {
    await removeConnection(event.dbClient);
    getIt<AppData>().bloc.add(UpdateUIEvent());
  }

  Future<void> _onUpdateDbStatus(
    UpdateDbStatus event,
    Emitter<DatabaseState> emit,
  ) async {
    emit(CheckingConnection());
    
    try {
      if (!await event.dbClient.ping()) {
        await _connectAndPull(event.dbClient);
      } else {
        await event.dbClient.pullDatabaseModel(getLastRows: false);
        await _applySavedPreferences(event.dbClient);

        // Get last row now that we have the saved orderBys
        for (final table in event.dbClient.tables) {
          await event.dbClient.getLastRow(table);
        }
        
        // Update AppData state to notify UI
        getIt<AppData>().updateDatabaseState(event.dbClient);
        
        add(ConnectionSuccessfulEvent(event.dbClient));
      }
    } catch (e, stackTrace) {
      debugPrint('Error updating database status: $e');
      debugPrint(stackTrace.toString());
      add(ConnectionErrorEvent(e, event.dbClient));
    }
  }

  Future<void> _onUpdateUIAfter(
    UpdateUIAfter event,
    Emitter<DatabaseState> emit,
  ) async {
    await event.code();
    getIt<AppData>().bloc.add(UpdateUIEvent());
  }

  Future<void> removeConnection(DbClient dbClient) async {
    await dbClient.disconnect();
    getIt<AppData>().dbs.remove(dbClient);
    await getIt<AppData>().removeConnection(dbClient);
    await getIt<AppData>().checkLocalDataStatus();
  }

  Future<void> _connectAndPull(
    DbClient dbClient, {
    bool fromForm = false,
  }) async {
    try {
      await dbClient.connect();
      await dbClient.pullDatabaseModel(getLastRows: false);

      // If not from form, apply saved user preferences to the table objects
      if (fromForm) {
        await getIt<AppData>().saveTables(dbClient);
      } else {
        await _applySavedPreferences(dbClient);
      }

      // Get last row now that we have the saved orderBys
      for (final table in dbClient.tables) {
        await dbClient.getLastRow(table);
      }
      
      // Update AppData state to notify UI
      getIt<AppData>().updateDatabaseState(dbClient);
      
      add(ConnectionSuccessfulEvent(dbClient));
    } on Exception catch (e, stacktrace) {
      add(ConnectionErrorEvent(e, dbClient));
      debugPrint(stacktrace.toString());
    } on Error catch (e, stacktrace) {
      add(ConnectionErrorEvent(e, dbClient));
      debugPrint(stacktrace.toString());
    }
  }

  /// Apply saved preferences (visibility and orderBy) to tables
  Future<void> _applySavedPreferences(DbClient dbClient) async {
    final savedTables = await getIt<AppData>().localDb.query(
      'tables',
      where: "host = ? AND port = ? AND db_name = ?",
      whereArgs: [
        dbClient.params.host,
        dbClient.params.port,
        dbClient.params.dbName,
      ],
    );

    for (final savedTable in savedTables) {
      final tableName = savedTable['name'] as String;
      final tableQuery = dbClient.tables.where((t) => t.name == tableName);
      
      if (tableQuery.isEmpty) {
        // If table was deleted, delete from local storage
        await getIt<AppData>().localDb.delete(
          "tables",
          where: "host = ? AND port = ? AND db_name = ? AND name = ?",
          whereArgs: [
            dbClient.params.host,
            dbClient.params.port,
            dbClient.params.dbName,
            tableName,
          ],
        );
      } else {
        final table = tableQuery.first;
        table.visible = savedTable['visible'] == 1;
        
        final orderByName = savedTable['order_by'] as String?;
        if (orderByName != null) {
          final orderByProperty = table.properties
              .where((property) => property.name == orderByName)
              .firstOrNull;
          if (orderByProperty != null) {
            table.orderBy = orderByProperty;
          }
        }
      }
    }
  }
}
