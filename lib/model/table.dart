import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/main.dart';
import 'package:equatable/equatable.dart';
import 'package:bitacora/model/property.dart';
import 'package:bitacora/model/app_data.dart';
import 'package:sqflite/sqflite.dart';

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
    getIt<AppData>().localDb.update("tables", {"order_by": _orderBy?.name},
        where: "host = ? AND port = ? AND db_name = ? AND name = ?",
        whereArgs: [
          client.params.host,
          client.params.port,
          client.params.dbName,
          name
        ]);
  }

  set visible(bool visible) {
    _visible = visible;
    getIt<AppData>().localDb.update("tables", {"visible": _visible ? 1 : 0},
        where: "host = ? AND port = ? AND db_name = ? AND name = ?",
        whereArgs: [
          client.params.host,
          client.params.port,
          client.params.dbName,
          name
        ]);
  }

  Table(this.name, this.properties, this.client);

  save({ConflictAlgorithm conflictAlgorithm: ConflictAlgorithm.replace}) async {
    await getIt<AppData>().localDb.insert(
          'tables',
          await toMap(),
          conflictAlgorithm: conflictAlgorithm,
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
