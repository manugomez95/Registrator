import 'dart:async';
import 'package:bitacora/main.dart';
import 'package:bitacora/model/app_data.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import './bloc.dart';

// TODO move all logic to the blocs
// Bloc per page?
// DB level and table level bloc?
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
      event.client.connect(fromForm: event.fromForm);
      if (event.fromForm) Navigator.of(event.context).pop(); // exit alertDialog
    }
    else if (event is ConnectionSuccessfulEvent) {
      if (event.fromForm) getIt<AppData>().dbs.add(event.client);
      yield ConnectionSuccessful(event.client);
    }
    else if (event is ConnectionErrorEvent) {
      Fluttertoast.showToast(msg: "${event.client.params.alias} not connected", toastLength: Toast.LENGTH_LONG);
      yield ConnectionError(event.exception);
    }
    else if (event is DisconnectFromDatabase) {
      try {
        await event.client.disconnect();
        getIt<AppData>().dbs.remove(event.client);
        yield DisconnectionSuccessful(event.client);
      } on Exception catch (e) {
        add(ConnectionErrorEvent(event.client, e));
      }
    }
    else if (event is UpdateDbsStatus) {
      getIt<AppData>().dbs.forEach((db) async {
        if (!await db.ping()) db.connect();
      });
    }

  }
}
