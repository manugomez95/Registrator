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

  Future<void> _handleFormResult(Map<String, dynamic>? formData) async {
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

        // Create the database client
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

        // Add the database to the list immediately to show it in the UI
        setState(() {
          getIt<AppData>().dbs.add(db);
          expandedItems.add(db.params.alias);
        });

        // Save the connection parameters
        await getIt<AppData>().saveConnection(db);

        // Connect and load tables in the background
        db.databaseBloc.add(ConnectToDatabase(db));

      } catch (e) {
        Fluttertoast.showToast(
          msg: "Error creating connection: ${e.toString()}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        print("Error creating database connection: $e");
      }
    }
  }

  Future<void> _refreshDatabase(DbClient db) async {
    try {
      if (await db.ping()) {
        await db.pullDatabaseModel(getLastRows: false);
        db.databaseBloc.add(ConnectionSuccessfulEvent(db));
      } else {
        db.databaseBloc.add(UpdateDbStatus(db));
      }
    } catch (e) {
      debugPrint('Error refreshing ${db.params.alias}: $e');
      db.databaseBloc.add(ConnectionErrorEvent(e, db));
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
                    // Show refreshing toast
                    Fluttertoast.showToast(
                      msg: "Refreshing connections...",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                    );

                    final dbs = getIt<AppData>().dbs.toList();
                    
                    // Refresh one database at a time
                    for (final db in dbs) {
                      // Schedule the refresh on the next frame to keep UI responsive
                      await Future.delayed(Duration.zero);
                      db.databaseBloc.add(UpdateDbStatus(db));
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
                  await _handleFormResult(result as Map<String, dynamic>?);
                },
              ),
            );
          },
        ));
  }
}
