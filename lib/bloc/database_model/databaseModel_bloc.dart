import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../postgresClient.dart';
import './bloc.dart';

class DatabaseModelBloc extends Bloc<DatabaseModelEvent, DatabaseModelState> {
  @override
  DatabaseModelState get initialState => DatabaseModelInitial();

  @override
  Stream<DatabaseModelState> mapEventToState(
    DatabaseModelEvent event,
  ) async* {
    if (event is GetDatabaseModel) {
      yield DatabaseModelLoading();
      final dbModel = await PostgresClient.getDatabaseModel(event.dbName);
      //DatabaseModel("my_data", [Table("imdb", [Property("titulo", PostgreSQLDataType.date)]), Table("spotify", [Property("cantante", PostgreSQLDataType.date)])]);
      yield DatabaseModelLoaded(dbModel);
    }
  }
}
