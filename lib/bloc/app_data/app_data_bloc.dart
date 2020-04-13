import 'dart:async';
import 'package:bloc/bloc.dart';
import './bloc.dart';

class AppDataBloc extends Bloc<AppDataEvent, AppDataState> {
  @override
  AppDataState get initialState => InitialAppDataState();

  @override
  Stream<AppDataState> mapEventToState(
    AppDataEvent event,
  ) async* {
    if (event is UpdateUIEvent) {
      yield UpdateUI(event.client);
    }
    else if (event is LoadingEvent) {
      yield Loading();
    }
  }
}
