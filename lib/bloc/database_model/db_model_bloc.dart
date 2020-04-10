import 'dart:async';
import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:bitacora/main.dart';
import 'package:bitacora/model/app_data.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import './bloc.dart';

// TODO move all logic to the blocs
class DatabaseModelBloc extends Bloc<DatabaseModelEvent, DatabaseModelState> {
  @override
  DatabaseModelState get initialState => DatabaseModelInitial();

  @override
  Stream<DatabaseModelState> mapEventToState(
    DatabaseModelEvent event,
  ) async* {
    if (event is ConnectToDatabase) {
      yield AttemptingDbConnection();
      // Asynchronously opens the connection and gets table info. We don't wait for this so the BLoC event loop is not blocked.
      PostgresClient.create(event.db);
      if (event.fromForm) Navigator.of(event.context).pop(); // exit alertDialog
    }
    else if (event is ConnectionSuccessfulEvent) {
      getIt<AppData>().dbs.add(event.client);
      yield ConnectionSuccessful(event.client);
    }
    else if (event is ConnectionErrorEvent) {
      yield ConnectionError(event.exception);
      Fluttertoast.showToast(msg: "${event.client.name} not connected", toastLength: Toast.LENGTH_LONG);
      print(event.exception);
      throw event.exception;
    }
    else if (event is DisconnectFromDatabase) {
      try {
        debugPrint("DisconnectFromDatabase: ${await event.client.connection.close()}");
        getIt<AppData>().dbs.remove(event.client);
        yield DisconnectionSuccessful(event.client);
      } on Exception catch (e) {
        yield ConnectionError(e);
        Fluttertoast.showToast(msg: "Connection error");
        print(e);
        throw e;
      }
    }
    else if (event is UpdateDbsStatus) {
      getIt<AppData>().dbs.forEach((db) {
        db.updateStatus();
      });
    }

  }
}
