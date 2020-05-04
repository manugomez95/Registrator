import 'package:equatable/equatable.dart';

abstract class DatabaseState extends Equatable {
  const DatabaseState();
}

class CheckingConnection extends DatabaseState {
  @override
  List<Object> get props => [];
}

/// This state manifests itself as the green icon in the db panel
class ConnectionSuccessful extends DatabaseState {
  @override
  List<Object> get props => [];
}

/// This state manifests itself as the red icon in the db panel
class ConnectionError extends DatabaseState {
  final Exception e;

  ConnectionError(this.e);

  @override
  List<Object> get props => [e];
}