import 'dart:async';
import 'package:bloc/bloc.dart';
import './bloc.dart';
import 'package:stack/stack.dart';

class AppDataBloc extends Bloc<AppDataEvent, AppDataState> {
  Stack<AppDataEvent> loadingStack = Stack();

  @override
  AppDataState get initialState => InitialAppDataState(loadingStack);

  @override
  Stream<AppDataState> mapEventToState(
    AppDataEvent event,
  ) async* {
    if (event is UpdateUIEvent || event is AltUpdateUIEvent) {
      if (loadingStack.isNotEmpty) loadingStack.pop();
      print("hola");
      yield UpdateUI(event, loadingStack);
    }
    else if (event is LoadingEvent) {
      loadingStack.push(event);
      yield Loading(loadingStack);
    }
  }
}
