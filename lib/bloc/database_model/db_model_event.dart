import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

abstract class DatabaseModelEvent extends Equatable {
  const DatabaseModelEvent();
}

class ConnectToDatabase extends DatabaseModelEvent {
  final PostgresClient client;
  final BuildContext context;
  final bool fromForm;

  ConnectToDatabase(this.client, {this.context, this.fromForm: false});

  @override
  List<Object> get props => [this.client, this.context, this.fromForm];
}

class ConnectionSuccessfulEvent extends DatabaseModelEvent {
  final DbClient client;
  final bool fromForm;

  ConnectionSuccessfulEvent(this.client, this.fromForm);

  @override
  List<Object> get props => [this.client, this.fromForm];
}

class ConnectionErrorEvent extends DatabaseModelEvent {
  final DbClient client;
  final Exception exception;

  ConnectionErrorEvent(this.client, this.exception);

  @override
  List<Object> get props => [this.client, this.exception];
}

class DisconnectFromDatabase extends DatabaseModelEvent {
  final DbClient client;

  DisconnectFromDatabase(this.client);

  @override
  List<Object> get props => [client];
}

class UpdateDbsStatus extends DatabaseModelEvent {
  @override
  List<Object> get props => null;
}