import 'package:equatable/equatable.dart';

abstract class TableState extends Equatable {
  const TableState();
}

class InitialTableState extends TableState {
  @override
  List<Object> get props => [];
}
