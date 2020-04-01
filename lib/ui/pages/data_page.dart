import 'package:bitacora/assets/my_custom_icons.dart';
import 'package:bitacora/bloc/database_model/db_model_bloc.dart';
import 'package:bitacora/bloc/database_model/db_model_state.dart';
import 'package:bitacora/conf/style.dart';
import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:bitacora/main.dart';
import 'package:bitacora/model/app_data.dart';
import 'package:bitacora/ui/components/db_form.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
              body: ListView(
                padding: new EdgeInsets.all(Style.scaffoldPadding),
                children:
                    getIt<AppData>().dbs.map((db) => DatabaseCard(db)).toList(),
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
}

class DatabaseCard extends StatelessWidget {
  DatabaseCard(this.db);

  final PostgresClient db;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(15),
            color: Style.lightGrey,
            child: Row(
              children: <Widget>[
                Container(
                  child: Icon(MyCustomIcons.database, size: 50),
                  padding: EdgeInsets.only(left: 5, right: 15),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text("Titulo"),
                    Text(db.connection.host),
                    Text(db.connection.databaseName),
                    Text(db.connection.username),
                  ],
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {},
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
