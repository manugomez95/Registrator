import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

abstract class DatabaseEvent extends Equatable {
  const DatabaseEvent();
}

class ConnectToDatabase extends DatabaseEvent {
  final DbClient dbClient;
  final BuildContext context;
  final bool fromForm;

  ConnectToDatabase(this.dbClient, {this.context, this.fromForm: false});

  @override
  List<Object> get props => [this.dbClient, this.context, this.fromForm];
}

class ConnectionSuccessfulEvent extends DatabaseEvent {
  final DbClient dbClient;

  ConnectionSuccessfulEvent(this.dbClient);

  @override
  List<Object> get props => [this.dbClient];
}

class ConnectionErrorEvent extends DatabaseEvent {
  final Exception exception;

  ConnectionErrorEvent(this.exception);

  @override
  List<Object> get props => [this.exception];
}

class RemoveConnection extends DatabaseEvent {
  final DbClient dbClient;

  RemoveConnection(this.dbClient);

  @override
  List<Object> get props => [dbClient];
}

class UpdateDbStatus extends DatabaseEvent {
  final DbClient dbClient;

  UpdateDbStatus(this.dbClient);

  @override
  List<Object> get props => [dbClient];
}

class UpdateUIAfter extends DatabaseEvent {
  final Function code;

  UpdateUIAfter(this.code);

  @override
  List<Object> get props => [code];
}