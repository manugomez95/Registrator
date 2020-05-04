import 'dart:async';
import 'package:bitacora/bloc/app_data/app_data_event.dart';
import 'package:bitacora/main.dart';
import 'package:bitacora/model/app_data.dart';
import 'package:bloc/bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import './bloc.dart';
import 'package:flutter/material.dart';

class DatabaseBloc extends Bloc<DatabaseEvent, DatabaseState> {
  @override
  DatabaseState get initialState => CheckingConnection();

  connectAndPull(ConnectToDatabase event) async {
    try {
      await event.dbClient.connect();
      await event.dbClient.pullDatabaseModel();
      add(ConnectionSuccessfulEvent(event.dbClient));
    } on Exception catch (e) {
      // if (verbose) debugPrint("connect (${this.params.alias}): ${e.toString()}");
      await event.dbClient.disconnect();
      Fluttertoast.showToast(msg: "${event.dbClient.params.alias}: ${e.toString()}", toastLength: Toast.LENGTH_LONG);
      add(ConnectionErrorEvent(e));
    }

    /// if first time connection (connection from form) save it
    if (event.fromForm) {
      getIt<AppData>().dbs.add(event.dbClient);
      await getIt<AppData>().saveConnection(event.dbClient);
      print(await getIt<AppData>().connections()); // TODO remove
    }
  }

  @override
  Stream<DatabaseState> mapEventToState(
    DatabaseEvent event,
  ) async* {
    if (event is ConnectToDatabase) {
      yield CheckingConnection();
      /// Connect and pull db model async to not block the event loop
      connectAndPull(event);
      if (event.fromForm) Navigator.of(event.context).pop(); // exit alertDialog
      getIt<AppData>().bloc.add(LoadingEvent());
    }
    else if (event is ConnectionSuccessfulEvent) {
      yield ConnectionSuccessful();
      getIt<AppData>().bloc.add(UpdateUIEvent());
    }
    else if (event is ConnectionErrorEvent) {
      yield ConnectionError(event.exception);
      getIt<AppData>().bloc.add(UpdateUIEvent());
    }
    else if (event is RemoveConnection) {
      try {
        await event.client.disconnect();

        getIt<AppData>().dbs.remove(event.client);
        await getIt<AppData>().removeConnection(event.client);
        print(await getIt<AppData>().connections());

        getIt<AppData>().bloc.add(UpdateUIEvent());
      } on Exception catch (e) {
        add(ConnectionErrorEvent(e)); // TODO never the case
      }
    }
    else if (event is UpdateDbStatus) {
      yield CheckingConnection();
      if (!await event.client.ping()) event.client.connect();
      //await event.client.pullDatabaseModel(); TODO
    }
    /// useful for general cases where we want to execute async code and then update the UI
    else if (event is UpdateUIAfter) {
      await event.code();
      getIt<AppData>().bloc.add(UpdateUIEvent());
    }
  }
}
