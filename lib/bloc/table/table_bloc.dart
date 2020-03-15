import 'dart:async';
import 'package:bloc/bloc.dart';
import './bloc.dart';

class TableBloc extends Bloc<TableEvent, TableState> {
  @override
  TableState get initialState => InitialTableState();

  @override
  Stream<TableState> mapEventToState(
    TableEvent event,
  ) async* {
    // TODO: Add Logic
  }
}
