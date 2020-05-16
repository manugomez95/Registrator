import 'package:bitacora/bloc/database/database_event.dart';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'form_field_view.dart';
import 'package:bitacora/conf/style.dart';

enum DbFormType {
  connect,
  edit
}

/// Needs to be Stateful because it contains a CheckBox
class DbForm extends StatefulWidget {
  final aliasController = TextEditingController();
  final hostController = TextEditingController();
  final portController = TextEditingController();
  final dbNameController = TextEditingController();
  final userController = TextEditingController();
  final passwordController = TextEditingController();
  final ValueNotifier<bool> useSSL = ValueNotifier(false);

  final formKey = GlobalKey<FormState>();
  final DbClient db;
  final DbFormType type;

  DbForm(this.type, {this.db}) {
    if (db != null) {
      aliasController.text = db.params.alias;
      hostController.text = db.params.host;
      portController.text = db.params.port.toString();
      dbNameController.text = db.params.dbName;
      userController.text = db.params.username;
    }
  }

  @override
  State<StatefulWidget> createState() => DbFormState();

  // TODO: first try to connect to the new "edition", if success remove previous
  editConnection(DbClient db) async {
      db.databaseBloc.removeConnection(db);
      final params = DbConnectionParams(
          aliasController.text,
          hostController.text,
          int.parse(portController.text),
          dbNameController.text,
          userController.text,
          passwordController.text,
          useSSL.value);
      DbClient newDb = PostgresClient(params);
      newDb.databaseBloc.add(ConnectToDatabase(newDb, fromForm: true));
  }

  void submit() {
    PostgresClient db = PostgresClient(DbConnectionParams(
        aliasController.text,
        hostController.text,
        int.parse(portController.text),
        dbNameController.text,
        userController.text,
        passwordController.text,
        useSSL.value));

    db.databaseBloc
        .add(ConnectToDatabase(db, fromForm: true));
  }
}

class DbFormState extends State<DbForm> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type == DbFormType.connect ? "New connection" : "Edit ${widget.aliasController.text}"),
        actions: <Widget>[
          FlatButton(
            child: Text(
              "SAVE",
              style: theme.textTheme.button
                  .copyWith(color: theme.colorScheme.negativeDefaultTxtColor),
            ),
            onPressed: () {
              if (widget.formKey.currentState.validate()) {
                if (widget.type == DbFormType.connect) widget.submit();
                else if (widget.type == DbFormType.edit) widget.editConnection(widget.db);
                Navigator.of(context).pop(); // exit alertDialog
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: widget.formKey,
            child: Column(
              children: <Widget>[
                FormFieldView(Alias(), widget.aliasController),
                Row(
                  children: <Widget>[
                    Flexible(
                      child: FormFieldView(Host(), widget.hostController),
                    ),
                    Container(
                      width: 120,
                      margin: EdgeInsets.only(left: 16),
                      child: FormFieldView(Port(), widget.portController),
                    )
                  ],
                ),
                FormFieldView(DatabaseName(), widget.dbNameController),
                FormFieldView(Username(), widget.userController),
                FormFieldView(Password(), widget.passwordController),
                Container(width: 150, child: CheckboxListTile(
                  title: const Text('SSL'),
                  value: widget.useSSL.value,
                  onChanged: (value) {
                    setState(() {
                      widget.useSSL.value = !widget.useSSL.value;
                    });
                  },
                ),)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
