import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:equatable/equatable.dart';

class AppData extends Equatable {
  // TODO que tenga un BLOC

  // DbClients
  final Set<DbClient> dbs = Set();

  @override
  List<Object> get props => [dbs];

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
