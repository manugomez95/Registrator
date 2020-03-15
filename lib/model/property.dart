import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:postgres/postgres.dart';

class Property extends Equatable {
  final String name;
  final PostgreSQLDataType type;

  Property(this.name, this.type);

  @override
  List<Object> get props => [name, type];

  @override
  String toString() {
    return "$name ($type)";
  }
}