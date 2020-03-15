import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:registrator/model/property.dart';

class Table extends Equatable {
  final String name;
  final List<Property> properties;

  Table(this.name, this.properties);

  @override
  List<Object> get props => [name, properties];
}