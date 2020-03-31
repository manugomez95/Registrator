import 'package:bitacora/model/app_data.dart';
import 'package:equatable/equatable.dart';

abstract class AppDataState extends Equatable {
  const AppDataState();
}

class InitialAppDataState extends AppDataState {
  @override
  List<Object> get props => [];
}

class AppDataLoading extends AppDataState {
  @override
  List<Object> get props => null;
}

class AppDataLoaded extends AppDataState {
  final AppData appData;

  AppDataLoaded(this.appData);

  @override
  List<Object> get props => [appData];
}