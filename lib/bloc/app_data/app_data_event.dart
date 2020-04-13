import 'package:bitacora/db_clients/db_client.dart';
import 'package:equatable/equatable.dart';

abstract class AppDataEvent extends Equatable {
  const AppDataEvent();
}

class UpdateUIEvent extends AppDataEvent {
  final DbClient client;

  UpdateUIEvent(this.client);

  @override
  List<Object> get props => [client];
}

class LoadingEvent extends AppDataEvent {
  @override
  List<Object> get props => [];
}