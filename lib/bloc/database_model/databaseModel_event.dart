import 'package:equatable/equatable.dart';

abstract class DatabaseModelEvent extends Equatable {
  const DatabaseModelEvent();
}

class GetDatabaseModel extends DatabaseModelEvent {
  final String dbName;

  GetDatabaseModel(this.dbName);

  @override
  List<Object> get props => [dbName];
}