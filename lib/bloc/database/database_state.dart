import 'package:equatable/equatable.dart';

abstract class DatabaseState extends Equatable {
  const DatabaseState();
}

class DatabaseInitial extends DatabaseState {
  @override
  List<Object> get props => null;
}

class CheckingConnection extends DatabaseState {
  @override
  List<Object> get props => [];
}

class ConnectionSuccessful extends DatabaseState {
  @override
  List<Object> get props => [];
}

class DisconnectionSuccessful extends DatabaseState {
  DisconnectionSuccessful();

  @override
  List<Object> get props => [];
}

class ConnectionError extends DatabaseState {
  final Exception e;

  ConnectionError(this.e);

  @override
  List<Object> get props => [e];
}