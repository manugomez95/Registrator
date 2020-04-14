import 'package:bitacora/bloc/database/bloc.dart';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:equatable/equatable.dart';
import 'package:stack/stack.dart';

abstract class AppDataEvent extends Equatable {
  const AppDataEvent();
}

class UpdateUIEvent extends AppDataEvent {
  final DatabaseEvent event;

  UpdateUIEvent(this.event);

  @override
  List<Object> get props => [event];
}

class LoadingEvent extends AppDataEvent {
  @override
  List<Object> get props => [];
}