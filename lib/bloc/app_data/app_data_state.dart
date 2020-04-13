import 'package:bitacora/db_clients/db_client.dart';
import 'package:equatable/equatable.dart';

abstract class AppDataState extends Equatable {
  const AppDataState();
}

class InitialAppDataState extends AppDataState {
  @override
  List<Object> get props => [];
}

class UpdateUI extends AppDataState {
  final DbClient client;

  UpdateUI(this.client);

  @override
  List<Object> get props => [client];
}

class Loading extends AppDataState {
  @override
  List<Object> get props => [];
}
