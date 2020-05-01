import 'package:bitacora/conf/style.dart';
import 'package:bitacora/bloc/app_data/app_data_event.dart';
import 'package:bitacora/bloc/database/bloc.dart';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/model/app_data.dart';
import 'package:bitacora/model/property.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
            if (state is ConnectionSuccessful) {
              statusIcon = Icon(Icons.check,
                  size: 18, color: Theme.of(context).colorScheme.secondary);
            } else if (state is ConnectionError) {
              statusIcon = Icon(Icons.error_outline,
                  size: 18, color: Theme.of(context).colorScheme.error);
            } else {
              statusIcon = SizedBox(
                child: CircularProgressIndicator(
                  strokeWidth: 1,
                ),
                height: 14.0,
                width: 14.0,
              );
              //statusIcon = Icon(Icons.sync, size: 18, color: Colors.blueAccent,);
            }
            return Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(15),
              child: Row(
                children: <Widget>[
                  Container(
                    child: SvgPicture.asset('assets/images/postgresql_elephant.svg',
                        height: 75, width: 75, semanticsLabel: 'Postgres Logo'),
                    padding: EdgeInsets.only(left: 5, right: 25),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(bottom: 5),
                        child: Text(
                          db.params.alias,
                          style: Theme.of(context).textTheme.title,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: <Widget>[
                          Icon(
                            Icons.domain,
                            size: 18,
                          ),
                          Text(
                            db.params.host,
                            style: Theme.of(context)
                                .textTheme
                                .subtitle, //TextStyle(color: style.hintColor, fontSize: 15),
                          )
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: <Widget>[
                          Icon(Icons.storage, size: 18),
                          Text(
                            db.params.dbName,
                            style: Theme.of(context).textTheme.subtitle,
                          )
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: <Widget>[
                          Icon(Icons.person, size: 18),
                          Text(db.params.username,
                              style: Theme.of(context).textTheme.subtitle)
                        ],
                      ),
                    ],
                  ),
                  Spacer(),
                  statusIcon
                ],
              ),
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
  final DbForm dbForm = DbForm();

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
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                  title: Text("Add Postgres DB"),
                                  content: dbForm,
                                  actions: <Widget>[
                                    FlatButton(
                                      child: Text('Cancel',
                                          style: Theme.of(context).textTheme.button.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .defaultTextColor)),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    RaisedButton(
                                      child: Text('Submit'),
                                      onPressed: () async {
                                        if (dbForm.formKey.currentState.validate()) {
                                          await dbForm.changeConnection(widget.db); // TODO it should be an event like when normal submitting
                                        }
                                      },
                                    )
                                  ]);
                            });
                      }
                  ),
                  IconButton(
                    icon: Icon(
                        ((widget.db?.tables?.isEmpty ?? true) || (widget.db?.tables?.any((table) => table.visible) ?? true))
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey),
                    onPressed: () {
                      if (widget.db.isConnected) {
                        setState(() {
                          if (widget.db.tables.any((table) => !table.visible)) {
                            widget.db.tables
                                .forEach((table) => table.visible = true);
                          } else {
                            widget.db.tables
                                .forEach((table) => table.visible = false);
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
                      if (await asyncConfirmDialog(context, title: 'Remove ${widget.db.params.alias}?', message: 'This will close and remove the connection.')) {
                        setState(() {
                          // Remove the item from the data source.
                          widget.db.databaseBloc.add(DisconnectFromDatabase((widget.db)));
                          // Then show a snackbar.
                          Scaffold.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  "${widget.db.params.alias} removed"))); // TODO add undo and use made snackbar
                        });
                      }
                    },
                  )
                ],
              ),
              //color: Colors.grey[600],
            ),
            if (widget.db.tables?.isEmpty == false ?? false)
              buildTablesView(widget.db.tables)
          ],
        ));
  }

  buildTablesView(List<app.Table> tables) {
    return Column(
      children: <Widget>[
        Divider(
          indent: 20,
          endIndent: 20,
        ),
        Container(
            padding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
            child: Column(
              children: widget.db.tables
                  ?.map((app.Table table) => Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            SizedBox(
                              child: Text(
                                "${table.name}",
                                style: TextStyle(
                                    //fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                              width: 90,
                            ),
                            Text(
                              "ORDER BY ",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.secondary),
                            ),
                            DropdownButtonHideUnderline(
                              child: Container(
                                height: 25,
                                margin: EdgeInsets.all(0),
                                padding: EdgeInsets.symmetric(horizontal: 5.0),
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                        width: 1.5,
                                        style: BorderStyle.solid,
                                        color: Theme.of(context).colorScheme.secondary),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10.0)),
                                  ),
                                ),
                                child: DropdownButton<Property>(
                                  iconSize: 0,
                                  value: table.orderBy,
                                  onChanged: (Property newProperty) {
                                    setState(() {
                                      /// the user can choose to order a table by any field, doesn't matter its type
                                      table.orderBy = newProperty;
                                      // TODO is last row gotten? Not yet, do it
                                      getIt<AppData>()
                                          .bloc
                                          .add(UpdateUIEvent());
                                    });
                                  },
                                  items: table.properties
                                      .map<DropdownMenuItem<Property>>(
                                          (Property property) {
                                    return DropdownMenuItem<Property>(
                                      value: property,
                                      child: SizedBox(
                                        width: 100.0, // for example
                                        child: Center(
                                            child: FittedBox(
                                                fit: BoxFit.fitWidth,
                                                child: Text(property.name,
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Theme.of(context).colorScheme.secondary)))),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                table.visible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey[300],
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
                  ?.toList(),
            ))
      ],
    );
  }
}
