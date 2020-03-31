import 'dart:async';
import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:bitacora/main.dart';
import 'package:bitacora/model/app_data.dart';
import 'package:bloc/bloc.dart';
import './bloc.dart';

// TODO move all logic to the blocs
class DatabaseModelBloc extends Bloc<DatabaseModelEvent, DatabaseModelState> {
  @override
  DatabaseModelState get initialState => DatabaseModelInitial();

  @override
  Stream<DatabaseModelState> mapEventToState(
    DatabaseModelEvent event,
  ) async* {
    /*if (event is GetDatabaseModel) {
      yield DatabaseModelLoading();
      final tables = await event.client.getDatabaseModel();
      yield DatabaseModelLoaded(tables);
    }
    else*/ if (event is ConnectToDatabase) {
      yield AttemptingDbConnection();
      final client = await PostgresClient.create(event.host, event.port, event.dbName, username: event.username, password: event.password);
      await client.getDatabaseModel();
      getIt<AppData>().dbs.add(client);
      yield ConnectionSuccessful(client);
    }
  }
}
