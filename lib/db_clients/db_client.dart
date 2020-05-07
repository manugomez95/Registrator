import 'package:bitacora/bloc/database/bloc.dart';
import 'package:bitacora/model/property.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:flutter_svg/flutter_svg.dart';

// TODO comment on Exceptions vs booleans: https://softwareengineering.stackexchange.com/questions/330824/function-returning-true-false-vs-void-when-succeeding-and-throwing-an-exception
// commenting on previous: the bottleneck in this functions is usually the network and I/O operations so we can afford to throw exceptions
/// It needs to be equatable to:
/// - be able to compare tables
// ignore: must_be_immutable
abstract class DbClient<T> extends Equatable {
  /// BLoC
  // ignore: close_sinks
  DatabaseBloc databaseBloc;

  Widget logo;

  /// Database model
  DbConnectionParams params;
  Set<app.Table> tables;
  final Duration timeout;
  final Duration queryTimeout;

  Future<Map<String, dynamic>> toMap() async {
    return await params.toMap();
  }

  /// Connection
  @protected
  T connection;
  bool isConnected = false;

  DbClient(this.params, {this.timeout: const Duration(seconds: 3), this.queryTimeout: const Duration(seconds: 2)}) {
    databaseBloc = DatabaseBloc();
  }

  @override
  List<Object> get props => [this.params];

  /// Opens the connection already defined and updates the DB model // TODO not really aligned with the name?
  connect({verbose: false});

  setConnectionParams(DbConnectionParams params, {verbose});

  disconnect({verbose: false});

  Future<bool> ping({verbose: false});

  pullDatabaseModel({verbose: false, getLastRows: true});

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
