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
      try {
        final client = await PostgresClient.create(
            event.host, event.port, event.dbName, username: event.username,
            password: event.password);
        await client.getDatabaseModel();
        getIt<AppData>().dbs.add(client);
        if (event.fromForm) Navigator.of(event.context).pop(); // exit alertDialog
        yield ConnectionSuccessful(client);
      } on Exception catch (e) {
        yield ConnectionError(e);
        Fluttertoast.showToast(msg: "Connection error");
        print(e);
        throw e;
      }
    }
  }
}
