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
import 'package:flutter_form_builder/flutter_form_builder.dart';

class DataPage extends StatefulWidget {
  const DataPage();

  @override
  State<StatefulWidget> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  final _dbModelBloc = getIt<DatabaseModelBloc>(); // TODO actually it's a AppDataBloc

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (BuildContext context) => _dbModelBloc,
        child: BlocBuilder(
          bloc: _dbModelBloc,
          builder: (BuildContext context, DatabaseModelState state) {
            return Scaffold(
              body: ListView(
                padding: new EdgeInsets.all(Style.scaffoldPadding),
                children: getIt<AppData>().dbs.map((db) => DatabaseCard(db)).toList(),
              ),
              floatingActionButton: FloatingActionButton(
                child: Icon(Icons.add),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: DbForm(),
                        );
                      }
                  );
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
      child: Text(db.connection.databaseName),
    );
  }

}