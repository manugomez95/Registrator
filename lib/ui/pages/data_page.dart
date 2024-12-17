import 'dart:async';
import 'dart:isolate';
import 'package:bitacora/bloc/app_data/app_data_state.dart';
import 'package:bitacora/bloc/database/database_event.dart';
import 'package:bitacora/bloc/database/database_state.dart';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/main.dart';
import 'package:bitacora/model/app_data.dart';
import 'package:bitacora/ui/components/database_card.dart';
import 'package:bitacora/ui/components/db_form.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:bitacora/db_clients/sqlite_client.dart';
import 'package:bitacora/db_clients/bigquery_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DataPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => DataPageState();
}

class DataPageState extends State<DataPage> {
  // Track expanded items by their alias instead of the DbClient object
  Set<String> expandedItems = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> handleFormResult(Map<String, dynamic>? formData) async {
    if (formData != null) {
      try {
        // Validate required fields
        final requiredFields = ['alias', 'brand'];
        if (formData['brand'] != 'sqlite') {
          requiredFields.addAll(['host', 'port', 'db_name', 'username']);
        } else {
          requiredFields.add('db_name');
        }

        for (final field in requiredFields) {
          if (formData[field] == null || formData[field].toString().isEmpty) {
            throw Exception('$field is required');
          }
        }

        // Validate port number for non-sqlite databases
        if (formData['brand'] != 'sqlite') {
          final port = formData['port'];
          if (port is! int || port <= 0 || port > 65535) {
            throw Exception('Invalid port number');
          }
        }

        final connectionParams = DbConnectionParams(
          formData['alias'],
          formData['host'],
          formData['port'],
          formData['db_name'],
          formData['username'],
          formData['password'],
          formData['useSSL'],
          formData['brand'],
        );

        // Show connecting toast
        Fluttertoast.showToast(
          msg: "Connecting to ${formData['alias']}...",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );

        // Create or update the database client
        late final DbClient db;
        switch (formData['brand']) {
          case 'postgres':
            db = PostgresClient(connectionParams);
            break;
          case 'sqlite':
            db = SQLiteClient(connectionParams);
            break;
          case 'bigquery':
            db = BigQueryClient(connectionParams);
            break;
          default:
            throw Exception('Database type ${formData['brand']} not supported');
        }

        // Add or update the database in the list
        setState(() {
          // Remove old connection if editing
          if (formData['isEditing'] == true) {
            final oldDb = getIt<AppData>().dbs.firstWhere(
              (d) => d.params.alias == formData['alias'],
              orElse: () => throw Exception('Original connection not found'),
            );
            // Disconnect old connection and clear its state
            oldDb.disconnect();
            oldDb.databaseBloc.add(ConnectionErrorEvent(Exception('Connection closed'), oldDb));
            getIt<AppData>().dbs.remove(oldDb);
          }
          getIt<AppData>().dbs.add(db);
          expandedItems.add(db.params.alias);
        });

        // Save the connection parameters
        await getIt<AppData>().saveConnection(db);

        // Connect and load tables
        db.databaseBloc.add(ConnectToDatabase(db));
        await db.connect(verbose: true);
        await db.pullDatabaseModel();
        await getIt<AppData>().saveTables(db);
        db.databaseBloc.add(ConnectionSuccessfulEvent(db));

      } catch (e) {
        Fluttertoast.showToast(
          msg: "Error with connection: ${e.toString()}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: const Color(0xFFD32F2F),
          textColor: Colors.white,
        );
        debugPrint("Error with database connection: $e");
      }
    }
  }

  Future<void> _refreshDatabase(DbClient db) async {
    try {
      // Signal start of loading
      db.databaseBloc.add(ConnectToDatabase(db, fromForm: false));
      
      // Just pull the model again, no need to disconnect/reconnect
      await db.pullDatabaseModel(getLastRows: false);
      
      if (db.isConnected) {
        db.databaseBloc.add(ConnectionSuccessfulEvent(db));
      }
    } catch (e) {
      debugPrint('Error refreshing ${db.params.alias}: $e');
      db.databaseBloc.add(ConnectionErrorEvent(e, db));
      
      // If there's an error, try to reconnect
      try {
        if (!db.isConnected) {
          await db.connect(verbose: true);
          await db.pullDatabaseModel(getLastRows: false);
          db.databaseBloc.add(ConnectionSuccessfulEvent(db));
        }
      } catch (reconnectError) {
        debugPrint('Error reconnecting: $reconnectError');
        db.databaseBloc.add(ConnectionErrorEvent(reconnectError, db));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (BuildContext context) => getIt<AppData>().bloc,
        child: BlocBuilder(
          bloc: getIt<AppData>().bloc,
          builder: (BuildContext context, AppDataState state) {
            List<DbClient> dbs = getIt<AppData>().dbs.toList();

            return Scaffold(
              body: RefreshIndicator(
                child: ListView(
                  children: <Widget>[
                    if (dbs.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No database connections yet.\nTap the + button to add one.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      )
                    else
                      ...dbs.map((db) => Card(
                        margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ExpansionTile(
                          title: DatabaseCardHeader(db),
                          children: [DatabaseCardBody(db)],
                          onExpansionChanged: (expanded) {
                            setState(() {
                              if (expanded) {
                                expandedItems.add(db.params.alias);
                              } else {
                                expandedItems.remove(db.params.alias);
                              }
                            });
                          },
                          initiallyExpanded: expandedItems.contains(db.params.alias),
                        ),
                      )).toList(),
                    SizedBox(height: 50,)
                  ],
                ),
                onRefresh: () async {
                  try {
                    final dbs = getIt<AppData>().dbs.toList();
                    
                    // Refresh one database at a time
                    for (final db in dbs) {
                      // Schedule the refresh on the next frame to keep UI responsive
                      await Future.delayed(Duration.zero);
                      await _refreshDatabase(db);
                    }
                  } catch (e, stackTrace) {
                    debugPrint('Error during refresh: $e');
                    debugPrint(stackTrace.toString());
                    Fluttertoast.showToast(
                      msg: "Error refreshing connections",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: const Color(0xFFD32F2F),
                    );
                  }
                },
              ),
              floatingActionButton: FloatingActionButton(
                child: Icon(Icons.add),
                heroTag: "DataPageFB",
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DbForm(DbFormType.connect), fullscreenDialog: true),
                  );
                  await handleFormResult(result as Map<String, dynamic>?);
                },
              ),
            );
          },
        ));
  }
}
