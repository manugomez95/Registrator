import 'package:bitacora/bloc/database/database_event.dart';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/main.dart';
import 'package:bitacora/model/app_data.dart';
import 'package:bitacora/ui/components/database_card.dart';
import 'package:bitacora/ui/components/db_form.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bitacora/bloc/database/bloc.dart' as alt;

class DataPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => DataPageState();
}

class DataPageState extends State<DataPage> {
  final DbForm dbForm = DbForm();

  @override
  Widget build(BuildContext context) {
    List<DbClient> dbs = getIt<AppData>().dbs.toList();
    return Scaffold(
      body: RefreshIndicator(
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: dbs.length,
          itemBuilder: (context, index) {
            return Dismissible(
              key: ValueKey(dbs[index]),
              onDismissed: (direction) {
                setState(() {
                  // Remove the item from the data source.
                  dbs[index].databaseBloc.add(DisconnectFromDatabase((dbs[index])));
                  // Then show a snackbar.
                  Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text(
                          "${dbs[index].params.alias} removed"))); // TODO add undo and use made snackbar
                });
              },
              confirmDismiss: (direction) async {
                return _asyncConfirmDialog(context, dbs[index]);
              },
              background: Container(color: Colors.red),
              child: DatabaseCard(dbs[index]),
            );
          },
          separatorBuilder: (BuildContext context, int index) => Divider(
            height: 20,
            color: Colors.transparent,
          ),
        ),
        onRefresh: () async {
          getIt<AppData>().dbs.forEach((db) => db.databaseBloc.add(alt.UpdateDbsStatus(db))); // TODO redundant, in the future appdata saves bloc objects
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                    title: Text("Add Postgres DB"),
                    content: dbForm,
                    actions: <Widget>[
                      FlatButton(
                        child: Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      RaisedButton(
                        child: Text('Submit'),
                        onPressed: () {
                          if (dbForm.formKey.currentState.validate()) {
                            dbForm.submit(context);
                          }
                        },
                      )
                    ]);
              });
        },
      ),
    );
  }

  Future<bool> _asyncConfirmDialog(BuildContext context, DbClient db) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button for close dialog!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove ${db.params.alias}?'),
          content: const Text('This will close and remove the connection.'),
          actions: <Widget>[
            FlatButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            FlatButton(
              child: const Text('ACCEPT'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            )
          ],
        );
      },
    );
  }
}
