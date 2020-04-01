import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:equatable/equatable.dart';
import 'package:bitacora/model/database_model.dart';
import 'package:postgres/postgres.dart';

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

class DatabaseModelLoaded extends DatabaseModelState {
  final DatabaseModel dbModel;

  DatabaseModelLoaded(this.dbModel);

  @override
  List<Object> get props => [dbModel];
}

class AttemptingDbConnection extends DatabaseModelState {
  @override
  List<Object> get props => null;
}

class ConnectionSuccessful extends DatabaseModelState {
  final PostgresClient client;

  ConnectionSuccessful(this.client);

  @override
  List<Object> get props => [client];
}

class ConnectionError extends DatabaseModelState {
  final Exception e;

  ConnectionError(this.e);

  @override
  List<Object> get props => [e];
}