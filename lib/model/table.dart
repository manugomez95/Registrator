import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/main.dart';
import 'package:equatable/equatable.dart';
import 'package:bitacora/model/property.dart';
import 'package:bitacora/model/app_data.dart';

// ignore: must_be_immutable
class Table extends Equatable {
  final DbClient client;
  final String name;
  final Set<Property> properties;
  Property primaryKey;
  Property _orderBy;
  bool _visible = true;

  bool get visible => _visible;
  Property get orderBy => _orderBy;

  set orderBy(Property orderBy) {
    _orderBy = orderBy;
    save();
  }

  set visible(bool visible) {
    _visible = visible;
    save();
  }

  Table(this.name, this.properties, this.client);

  save() async {
    getIt<AppData>().database.update(
        'tables',
        await toMap(),
    where: "name = ? AND host = ? AND port = ? AND db_name = ?",
    // Pass the Dog's id as a whereArg to prevent SQL injection.
    whereArgs: [name, client.params.host, client.params.port, client.params.dbName],
    );
  }

  @override
  List<Object> get props => [name, client];

  Future<Map<String, dynamic>> toMap() async {
    return {
      'name': name,
      'primary_key': primaryKey?.name,
      'order_by': orderBy?.name,
      'visible': visible ? 1 : 0,
      'host': client.params.host,
      'port': client.params.port,
      'db_name': client.params.dbName
    };
  }

  @override
  String toString() {
    return name;
  }
}