import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:equatable/equatable.dart';

abstract class DatabaseModelEvent extends Equatable {
  const DatabaseModelEvent();
}

class ConnectToDatabase extends DatabaseModelEvent {
  final String host;
  final int port;
  final String dbName;
  final String username;
  final String password;

  ConnectToDatabase(this.host, this.port, this.dbName, this.username, this.password);

  @override
  List<Object> get props => [this.host, this.port, this.dbName, this.username, this.password];
}

class GetDatabaseModel extends DatabaseModelEvent {
  final PostgresClient client;

  GetDatabaseModel(this.client);

  @override
  List<Object> get props => [client];
}