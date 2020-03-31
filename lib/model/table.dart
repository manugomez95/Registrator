import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:equatable/equatable.dart';
import 'package:bitacora/model/property.dart';

class Table extends Equatable {
  final PostgresClient client;
  final String name;
  final List<Property> properties;

  Table(this.name, this.properties, this.client);

  @override
  List<Object> get props => [name, properties];
}