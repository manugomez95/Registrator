import 'package:equatable/equatable.dart';
import 'package:registrator/model/databaseModel.dart';

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
