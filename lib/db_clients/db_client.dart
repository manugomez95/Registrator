import 'package:bitacora/bloc/database/bloc.dart';
import 'package:bitacora/model/property.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:bitacora/model/table.dart' as app;


// ignore: must_be_immutable
abstract class DbClient<T> extends Equatable {
  /// BLoC
  // ignore: close_sinks
  DatabaseBloc databaseBloc;

  /// Database model
  DbConnectionParams params;
  List<app.Table> tables;
  final Duration timeout;
  final Duration queryTimeout;

  Future<Map<String, dynamic>> toMap() async {
    return await params.toMap();
  }

  /// Connection
  @protected
  T connection;
  bool isConnected = false;

  DbClient(this.params, {this.timeout: const Duration(seconds: 3), this.queryTimeout: const Duration(seconds: 2)});

  connect({verbose: false});

  changeConnection(DbConnectionParams params, {verbose});

  disconnect({verbose: false});

  ping({verbose: false});

  updateDatabaseModel({verbose: false});

  Future<List<String>> getTables({verbose: false});

  Future<Set<Property>> getPropertiesFromTable(String table, {verbose: false});

  getLastRow(app.Table table, {verbose: false});

  insertRowIntoTable(app.Table table, Map<Property, dynamic> propertiesForm, {verbose: false});

  editLastFrom(app.Table table, Map<Property, dynamic> propertiesForm, {verbose: false});

  /// Doesn't needs linearity defined
  cancelLastInsertion(app.Table table, Map<Property, dynamic> propertiesForm, {verbose: false});

  /// Needs linearity defined
  deleteLastFrom(app.Table table, {verbose: false});

  /// Table properties need to be already created and also the rest of the tables
  getKeys({verbose: false});

  Future<List<String>> getPkDistinctValues(app.Table table, {verbose: false, String pattern});
}
