import 'package:equatable/equatable.dart';

abstract class AppDataEvent extends Equatable {
  const AppDataEvent();
}

class GetAppData extends AppDataEvent {
  final String dbName;

  GetAppData(this.dbName);

  @override
  List<Object> get props => [dbName];
}