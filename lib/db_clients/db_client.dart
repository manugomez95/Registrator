import 'package:bitacora/model/property.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:bitacora/model/table.dart' as app;

// TODO change to some other class that implements PostgresClient/RelationalDBClient interface
// ignore: must_be_immutable
abstract class DbClient<T> extends Equatable {
  /// Database model TODO might be an object because not final properties
  DbDescription params;
  List<app.Table> tables;
  final Duration timeout;
  final Duration queryTimeout;

  /// Connection
  @protected
  T connection;
  bool isConnected = false;

  DbClient(this.params, {this.timeout: const Duration(seconds: 3), this.queryTimeout: const Duration(seconds: 2)});

  Future<bool> connect({verbose: false});

  disconnect({verbose: false});

  Future<bool> ping({verbose: false});

  updateDatabaseModel({verbose: false});

  Future<List<String>> getTables({verbose: false});

  Future<List<Property>> getPropertiesFromTable(String table, {verbose: false});

  getLastRow(app.Table table, {verbose: false});

  Future<bool> insertRowIntoTable(app.Table table, Map<String, String> propertiesForm, {verbose: false});

  Future<bool> updateLastRow(app.Table table, Map<String, String> propertiesForm, {verbose: false});

  Future<bool> cancelLastInsertion(app.Table table, Map<String, String> propertiesForm, {verbose: false});
}
