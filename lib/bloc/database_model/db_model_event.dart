import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

abstract class DatabaseModelEvent extends Equatable {
  const DatabaseModelEvent();
}

class ConnectToDatabase extends DatabaseModelEvent {
  final Database db;
  final BuildContext context;
  final bool fromForm;

  ConnectToDatabase(this.db, {this.context, this.fromForm: false});

  @override
  List<Object> get props => [this.db, this.context, this.fromForm];
}

class ConnectionSuccessfulEvent extends DatabaseModelEvent {
  final PostgresClient client;

  ConnectionSuccessfulEvent(this.client);

  @override
  List<Object> get props => [this.client];
}

class ConnectionErrorEvent extends DatabaseModelEvent {
  final PostgresClient client;
  final Exception exception;

  ConnectionErrorEvent(this.client, this.exception);

  @override
  List<Object> get props => [this.client, this.exception];
}

class DisconnectFromDatabase extends DatabaseModelEvent {
  final PostgresClient client;

  DisconnectFromDatabase(this.client);

  @override
  List<Object> get props => [client];
}

class UpdateDbsStatus extends DatabaseModelEvent {
  @override
  List<Object> get props => null;
}