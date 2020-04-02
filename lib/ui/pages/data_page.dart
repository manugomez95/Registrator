import 'package:bitacora/bloc/database_model/db_model_bloc.dart';
import 'package:bitacora/bloc/database_model/db_model_state.dart';
import 'package:bitacora/conf/style.dart';
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