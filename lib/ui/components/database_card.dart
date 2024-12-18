import 'package:bitacora/bloc/app_data/app_data_event.dart';
import 'package:bitacora/bloc/database/bloc.dart';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/model/app_data.dart';
import 'package:bitacora/model/property.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:bitacora/ui/pages/data_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../main.dart';
import 'confirm_dialog.dart';
import 'db_form.dart';

class DatabaseCardHeader extends StatelessWidget {
  DatabaseCardHeader(this.db);

  final DbClient db;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (BuildContext context) => db.databaseBloc,
        child: BlocBuilder(
          bloc: db.databaseBloc,
          builder: (BuildContext context, DatabaseState state) {
            Widget statusIcon;
            if (state is ConnectionSuccessful || db.isConnected) {
              statusIcon = Icon(Icons.check,
                  size: 18, color: Theme.of(context).colorScheme.secondary);
            } else if (state is ConnectionError) {
              statusIcon = Icon(Icons.error_outline,
                  size: 18, color: Theme.of(context).colorScheme.error);
            } else {
              // Show loading for any other state (including initial and checking)
              statusIcon = SizedBox(
                child: CircularProgressIndicator(
                  strokeWidth: 1,
                ),
                height: 14.0,
                width: 14.0,
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  child: Container(
                    child: db.getLogo(Theme.of(context).brightness),
                    width: 50,
                    height: 50,
                  ),
                  padding: EdgeInsets.only(right: 15),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        db.params.alias,
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Icon(Icons.domain, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              db.params.host,
                              style: Theme.of(context).textTheme.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Icon(Icons.storage, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              db.params.dbName,
                              style: Theme.of(context).textTheme.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (db.params.dbName != "demo.db")
                        Row(
                          children: <Widget>[
                            Icon(Icons.person, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                db.params.username,
                                style: Theme.of(context).textTheme.titleSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                statusIcon,
              ],
            );
          },
        ));
  }
}

class DatabaseCardBody extends StatefulWidget {
  DatabaseCardBody(this.db);

  final DbClient db;

  @override
  State<StatefulWidget> createState() => DatabaseCardBodyState();
}

class DatabaseCardBodyState extends State<DatabaseCardBody> {
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(bottom: 10),
        child: Column(
          children: <Widget>[
            Divider(
              indent: 20,
              endIndent: 20,
              height: 1,
            ),
            Container(
              padding: EdgeInsets.only(top: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: Colors.grey,
                      ),
                      onPressed: () async {
                        if (widget.db.params.dbName == "demo.db") {
                          Fluttertoast.showToast(msg: "Demo cannot be edited");
                        } else {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>
                                DbForm(DbFormType.edit, db: widget.db),
                                fullscreenDialog: true),
                          );
                          if (result != null) {
                            // Get the parent DataPage's state to handle the form result
                            final dataPageState = context.findAncestorStateOfType<DataPageState>();
                            if (dataPageState != null) {
                              await dataPageState.handleFormResult(result as Map<String, dynamic>);
                            }
                          }
                        }
                      }),
                  IconButton(
                    icon: Icon(
                        (widget.db.tables.isEmpty ||
                         widget.db.tables.any((table) => table.visible))
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey),
                    onPressed: () {
                      if (widget.db.isConnected) {
                        setState(() {
                          if (widget.db.tables.any((table) => !table.visible)) {
                            widget.db.tables.forEach((table) => table.visible = true);
                          } else {
                            widget.db.tables.forEach((table) => table.visible = false);
                          }
                        });
                        getIt<AppData>().bloc.add(UpdateUIEvent());
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: Colors.grey,
                    ),
                    onPressed: () async {
                      if (await asyncConfirmDialog(context,
                          title: 'Remove ${widget.db.params.alias}?',
                          message:
                              'This will close and remove the connection.')) {
                        try {
                          final appData = getIt<AppData>();
                          final dbAlias = widget.db.params.alias;

                          // First disconnect if connected
                          if (widget.db.isConnected) {
                            await widget.db.disconnect(verbose: true);
                          }

                          // Remove from runtime storage first
                          setState(() {
                            appData.dbs.remove(widget.db);
                          });

                          // Then remove from local storage
                          await appData.removeConnection(widget.db);
                          
                          // Notify the bloc to trigger UI update
                          getIt<AppData>().bloc.add(UpdateUIEvent());

                          // Show success message
                          Fluttertoast.showToast(
                            msg: "$dbAlias connection removed",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Colors.green,
                          );
                        } catch (e) {
                          // Show error message if removal fails
                          Fluttertoast.showToast(
                            msg: "Error removing connection: ${e.toString()}",
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.CENTER,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                          );
                          print("Error removing database connection: $e"); // For debugging
                        }
                      }
                    },
                  )
                ],
              ),
            ),
            if (!widget.db.tables.isEmpty)
              buildTablesView(widget.db.tables)
          ],
        ));
  }

  buildTablesView(Set<app.Table> tables) {
    return Column(
      children: <Widget>[
        Divider(
          indent: 20,
          endIndent: 20,
        ),
        Container(
            padding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
            height: 200,
            child: ListView(
                shrinkWrap: true,
                children: (tables.toList()..sort((a, b) => a.name.compareTo(b.name)))
                    .map<Widget>((table) => Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                flex: 2,
                                child: Text(
                                  table.name,
                                  style: TextStyle(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "ORDER BY",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.secondary),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: DropdownButtonHideUnderline(
                                  child: Container(
                                    height: 25,
                                    padding: EdgeInsets.symmetric(horizontal: 5.0),
                                    decoration: ShapeDecoration(
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(
                                          width: 1.5,
                                          style: BorderStyle.solid,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                      ),
                                    ),
                                    child: DropdownButton<Property>(
                                      isExpanded: true,
                                      iconSize: 16,
                                      value: table.orderBy,
                                      onChanged: (Property? newProperty) {
                                        if (newProperty != null) {
                                          setState(() {
                                            table.client.databaseBloc
                                                .add(UpdateUIAfter(() async {
                                              table.orderBy = newProperty;
                                              await table.client.getLastRow(table);
                                            }));
                                          });
                                        }
                                      },
                                      items: table.properties
                                          .map<DropdownMenuItem<Property>>(
                                              (Property property) {
                                            return DropdownMenuItem<Property>(
                                              value: property,
                                              child: Text(
                                                property.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.secondary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  table.visible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey[300],
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    table.visible = !table.visible;
                                  });
                                  getIt<AppData>().bloc.add(UpdateUIEvent());
                                },
                              )
                            ],
                          ),
                        ))
                    .toList(),
            ))
      ],
    );
  }
}
