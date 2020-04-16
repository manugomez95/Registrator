import 'package:bitacora/bloc/app_data/app_data_bloc.dart';
import 'package:bitacora/conf/style.dart';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'action.dart' as app;

class AppData {
  // ignore: close_sinks
  final AppDataBloc bloc = AppDataBloc();
  final Set<DbClient> dbs = Set();
  List<app.Action> actions;

  Iterable<DbClient> getDbs() {
    return dbs.where((db) => db.isConnected).toList();
  }

  Iterable<app.Table> getTables() {
    return getDbs()
        .map((DbClient db) => db.tables)
        ?.expand((i) => i)
        ?.toList();
  }
}
