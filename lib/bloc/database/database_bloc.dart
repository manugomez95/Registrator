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
  DatabaseState get initialState => DatabaseInitial();

  @override
  Stream<DatabaseState> mapEventToState(
    DatabaseEvent event,
  ) async* {
    if (event is ConnectToDatabase) {
      yield CheckingConnection();
      // Asynchronously opens the connection and gets table info. We don't wait for this so the BLoC event loop is not blocked.
      event.client.connect(fromForm: event.fromForm);
      if (event.fromForm) Navigator.of(event.context).pop(); // exit alertDialog
      getIt<AppData>().bloc.add(LoadingEvent());
    }
    else if (event is ConnectionSuccessfulEvent) {
      if (event.fromForm) getIt<AppData>().dbs.add(event.client);
      yield ConnectionSuccessful();
      getIt<AppData>().bloc.add(UpdateUIEvent(event.client));
    }
    else if (event is ConnectionErrorEvent) {
      Fluttertoast.showToast(msg: "${event.client.params.alias} not connected", toastLength: Toast.LENGTH_LONG);
      yield ConnectionError(event.exception);
      getIt<AppData>().bloc.add(UpdateUIEvent(event.client));
    }
    else if (event is DisconnectFromDatabase) {
      try {
        await event.client.disconnect();
        getIt<AppData>().dbs.remove(event.client);
        yield DisconnectionSuccessful();
        getIt<AppData>().bloc.add(UpdateUIEvent(event.client));
      } on Exception catch (e) {
        add(ConnectionErrorEvent(event.client, e));
      }
    }
    else if (event is UpdateDbsStatus) {
      yield CheckingConnection();
      if (!await event.client.ping()) event.client.connect();
    }

  }
}
