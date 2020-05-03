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
      /// if first time connection (connection from form) save it TODO check if works
      if (event.fromForm) {
        getIt<AppData>().dbs.add(event.client);
        await getIt<AppData>().saveConnection(event.client);
        print(await getIt<AppData>().connections());
      }
      yield ConnectionSuccessful();
      getIt<AppData>().bloc.add(UpdateUIEvent());
    }
    else if (event is ConnectionErrorEvent) {
      Fluttertoast.showToast(msg: "${event.client.params.alias}: ${event.exception.toString()}", toastLength: Toast.LENGTH_LONG);
      yield ConnectionError(event.exception);
      getIt<AppData>().bloc.add(UpdateUIEvent());
    }
    else if (event is RemoveConnection) {
      try {
        await event.client.disconnect();

        getIt<AppData>().dbs.remove(event.client);
        await getIt<AppData>().removeConnection(event.client);
        print(await getIt<AppData>().connections());

        yield DisconnectionSuccessful(); // TODO useless since it's only for the database and... its gone?
        getIt<AppData>().bloc.add(UpdateUIEvent());
      } on Exception catch (e) {
        add(ConnectionErrorEvent(event.client, e));
      }
    }
    else if (event is UpdateDbStatus) {
      yield CheckingConnection();
      if (!await event.client.ping()) event.client.connect();
    }

  }
}
