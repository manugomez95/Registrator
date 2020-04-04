import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

abstract class DatabaseModelEvent extends Equatable {
  const DatabaseModelEvent();
}

class ConnectToDatabase extends DatabaseModelEvent {
  final String name;
  final String host;
  final int port;
  final String dbName;
  final String username;
  final String password;
  final bool useSSL;
  final BuildContext context;
  final bool fromForm;

  ConnectToDatabase(this.name, this.host, this.port, this.dbName, this.username, this.password, {this.context, this.fromForm: false, this.useSSL: false});

  @override
  List<Object> get props => [this.name, this.host, this.port, this.dbName, this.username, this.password];
}

class DisconnectFromDatabase extends DatabaseModelEvent {
  final PostgresClient client;

  DisconnectFromDatabase(this.client);

  @override
  List<Object> get props => [client];
}