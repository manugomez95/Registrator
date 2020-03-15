import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:registrator/model/table.dart' as my;

class DatabaseModel extends Equatable {
  final String name;
  final List<my.Table> tables;

  DatabaseModel(this.name, this.tables);

  @override
  List<Object> get props => [name, tables];
}