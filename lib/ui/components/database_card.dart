import 'package:bitacora/assets/my_custom_icons.dart';
import 'package:bitacora/bloc/database_model/bloc.dart';
import 'package:bitacora/bloc/database_model/db_model_bloc.dart';
import 'package:bitacora/conf/style.dart';
import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:bitacora/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
                    Text(db.name),
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
                  onPressed: () async {
                    if (await _asyncConfirmDialog(context, db))
                      getIt<DatabaseModelBloc>().add(DisconnectFromDatabase(db));
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// TODO nice
Future<bool> _asyncConfirmDialog(BuildContext context, PostgresClient db) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // user must tap button for close dialog!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Remove ${db.connection.databaseName}?'),
        content: const Text(
            'This will close and remove the connection'),
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