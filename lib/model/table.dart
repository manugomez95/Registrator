import 'package:bitacora/db_clients/db_client.dart';
import 'package:equatable/equatable.dart';
import 'package:bitacora/model/property.dart';

// ignore: must_be_immutable
class Table extends Equatable {
  final DbClient client;
  final String name;
  final Set<Property> properties;
  bool visible;

  Table(this.name, this.properties, this.client);

  @override
  List<Object> get props => [name, client];

  @override
  String toString() {
    return name;
  }
}