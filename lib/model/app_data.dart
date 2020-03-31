import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:equatable/equatable.dart';

class AppData extends Equatable {
  final Set<PostgresClient> dbs = Set();

  @override
  List<Object> get props => [dbs];
}