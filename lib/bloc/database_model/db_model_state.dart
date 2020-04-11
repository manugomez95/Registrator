import 'package:bitacora/db_clients/db_client.dart';
import 'package:equatable/equatable.dart';

abstract class DatabaseModelState extends Equatable {
  const DatabaseModelState();
}

class DatabaseModelInitial extends DatabaseModelState {
  @override
  List<Object> get props => null;
}

class DatabaseModelLoading extends DatabaseModelState {
  @override
  List<Object> get props => null;
}

class AttemptingDbConnection extends DatabaseModelState {
  @override
  List<Object> get props => null;
}

class ConnectionSuccessful extends DatabaseModelState {
  final DbClient client;

  ConnectionSuccessful(this.client);

  @override
  List<Object> get props => [client];
}

class DisconnectionSuccessful extends DatabaseModelState {
  final DbClient client;

  DisconnectionSuccessful(this.client);

  @override
  List<Object> get props => [client];
}

class ConnectionError extends DatabaseModelState {
  final Exception e;

  ConnectionError(this.e);

  @override
  List<Object> get props => [e];
}

class DbsStatusUpdated extends DatabaseModelState {
  @override
  List<Object> get props => [];
}