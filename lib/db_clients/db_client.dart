import 'package:bitacora/bloc/database/bloc.dart';
import 'package:bitacora/model/property.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:bitacora/model/table.dart' as app;

// TODO change to some other class that implements PostgresClient/RelationalDBClient interface
// ignore: must_be_immutable
abstract class DbClient<T> extends Equatable {
  /// BLoC
  // ignore: close_sinks
  DatabaseBloc databaseBloc;

  /// Database model TODO might be an object because not final properties
  DbConnectionParams params;
  List<app.Table> tables;
  final Duration timeout;
  final Duration queryTimeout;

  /// Connection
  @protected
  T connection;
  bool isConnected = false;

  DbClient(this.params, {this.timeout: const Duration(seconds: 3), this.queryTimeout: const Duration(seconds: 2)});

  Future<bool> connect({verbose: false});

  changeConnection(DbConnectionParams params, {verbose});

  disconnect({verbose: false});

  Future<bool> ping({verbose: false});

  updateDatabaseModel({verbose: false});

  Future<List<String>> getTables({verbose: false});

  Future<Set<Property>> getPropertiesFromTable(String table, {verbose: false});

  getLastRow(app.Table table, {verbose: false});

  Future<bool> insertRowIntoTable(app.Table table, Map<Property, dynamic> propertiesForm, {verbose: false});

  Future<bool> editLastFrom(app.Table table, Map<Property, dynamic> propertiesForm, {verbose: false});

  /// Doesn't needs linearity defined
  Future<bool> cancelLastInsertion(app.Table table, Map<Property, dynamic> propertiesForm, {verbose: false});

  /// Needs linearity defined
  deleteLastFrom(app.Table table, {verbose: false});

  /// Table properties need to be already created and also the rest of the tables
  getKeys({verbose: false});

  Future<List<String>> getPkDistinctValues(app.Table table, {verbose: false, String pattern});
}
