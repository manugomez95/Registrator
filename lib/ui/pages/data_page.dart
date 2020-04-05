import 'package:bitacora/bloc/database_model/db_model_bloc.dart';
import 'package:bitacora/bloc/database_model/db_model_event.dart';
import 'package:bitacora/bloc/database_model/db_model_state.dart';
import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:bitacora/main.dart';
import 'package:bitacora/model/app_data.dart';
import 'package:bitacora/ui/components/database_card.dart';
import 'package:bitacora/ui/components/db_form.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DataPage extends StatefulWidget {
  const DataPage();

  @override
  State<StatefulWidget> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  final _dbModelBloc =
      getIt<DatabaseModelBloc>(); // TODO actually it's a AppDataBloc

  @override
  Widget build(BuildContext context) {
    final DbForm dbForm = DbForm();
    return BlocProvider(
        create: (BuildContext context) => _dbModelBloc,
        child: BlocBuilder(
          bloc: _dbModelBloc,
          builder: (BuildContext context, DatabaseModelState state) {
            return Scaffold(
              body: ListView.separated(
                itemCount: getIt<AppData>().dbs.toList().length,
                itemBuilder: (context, index) {
                  return Dismissible(
                    key: ValueKey(getIt<AppData>().dbs.toList()[index]),
                    onDismissed: (direction) {
                      // Remove the item from the data source.
                      setState(() {
                        getIt<DatabaseModelBloc>()
                            .add(DisconnectFromDatabase(getIt<AppData>().dbs.toList()[index]));
                      });
                      // Then show a snackbar.
                      Scaffold.of(context).showSnackBar(
                          SnackBar(content: Text("${getIt<AppData>().dbs.toList()[index]} dismissed")));
                    },
                    confirmDismiss: (direction) async {
                      return _asyncConfirmDialog(context, getIt<AppData>().dbs.toList()[index]);
                    },
                    background: Container(color: Colors.red),
                    child: DatabaseCard(getIt<AppData>().dbs.toList()[index]),
                  );
                },
                separatorBuilder: (BuildContext context, int index) => Divider(height: 20, color: Colors.transparent,),
              ),
              floatingActionButton: FloatingActionButton(
                child: Icon(Icons.add),
                onPressed: () {
                  setState(() {
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
                                    if (dbForm.formKey.currentState
                                        .validate()) {
                                      dbForm.submit(context);
                                    }
                                  },
                                )
                              ]);
                        });
                  });
                },
              ),
            );
          },
        ));
  }

  @override
  void dispose() {
    super.dispose();
    _dbModelBloc.close();
  }

  Future<bool> _asyncConfirmDialog(
      BuildContext context, PostgresClient db) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button for close dialog!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove ${db.name}?'),
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
