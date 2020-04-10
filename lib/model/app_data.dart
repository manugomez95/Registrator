import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:equatable/equatable.dart';

class AppData extends Equatable {
  // TODO que tenga un BLOC

  final Set<PostgresClient> dbs = Set();

  Future<bool> connectToDatabase() async {
    return true;
  }

  @override
  List<Object> get props => [dbs];
}