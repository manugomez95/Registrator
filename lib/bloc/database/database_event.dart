import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

abstract class DatabaseEvent extends Equatable {
  const DatabaseEvent();
}

class ConnectToDatabase extends DatabaseEvent {
  final PostgresClient client;
  final BuildContext context;
  final bool fromForm;

  ConnectToDatabase(this.client, {this.context, this.fromForm: false});

  @override
  List<Object> get props => [this.client, this.context, this.fromForm];
}

class ConnectionSuccessfulEvent extends DatabaseEvent {
  final DbClient client;
  final bool fromForm;

  ConnectionSuccessfulEvent(this.client, this.fromForm);

  @override
  List<Object> get props => [this.client, this.fromForm];
}

class ConnectionErrorEvent extends DatabaseEvent {
  final DbClient client;
  final Exception exception;

  ConnectionErrorEvent(this.client, this.exception);

  @override
  List<Object> get props => [this.client, this.exception];
}

class DisconnectFromDatabase extends DatabaseEvent {
  final DbClient client;

  DisconnectFromDatabase(this.client);

  @override
  List<Object> get props => [client];
}

class UpdateDbStatus extends DatabaseEvent {
  final DbClient client;

  UpdateDbStatus(this.client);

  @override
  List<Object> get props => [client];
}