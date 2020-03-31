import 'dart:async';
import 'package:bitacora/model/app_data.dart';
import 'package:bloc/bloc.dart';
import './bloc.dart';

class AppDataBloc extends Bloc<AppDataEvent, AppDataState> {
  @override
  AppDataState get initialState => InitialAppDataState();

  @override
  Stream<AppDataState> mapEventToState(
    AppDataEvent event,
  ) async* {
    if (event is GetAppData) {
      yield AppDataLoading();
      AppData appData;
      //final dbModel = await getIt<PostgresClient>().getDatabaseModel(event.dbName);
      yield AppDataLoaded(appData);
    }
  }
}
