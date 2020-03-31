import 'package:equatable/equatable.dart';
import 'package:bitacora/model/table.dart' as app;

class DatabaseModel extends Equatable {
  final List<app.Table> tables;

  DatabaseModel(this.tables);
  @override
  List<Object> get props => [tables];
}