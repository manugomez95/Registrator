import 'package:bitacora/bloc/app_data/app_data_bloc.dart';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'action.dart' as app;


class AppData {

  // ignore: close_sinks
  final AppDataBloc bloc = AppDataBloc();

  final Set<DbClient> dbs = Set();
  Future<SharedPreferences> sharedPrefs;

  Iterable<DbClient> getDbs() {
    return dbs.where((db) => db.isConnected).toList();
  }

  Iterable<app.Table> getTables({bool onlyVisibles : true}) {
    return getDbs()
        .map((DbClient db) => onlyVisibles ? db.tables.where((table) => table.visible) : db.tables)
        ?.expand((i) => i)
        ?.toList();
  }
}
