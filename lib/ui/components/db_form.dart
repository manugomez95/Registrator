import 'package:bitacora/bloc/database/database_event.dart';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'form_field_view.dart';

class DbForm extends StatefulWidget {
  final nameController = TextEditingController();
  final hostController = TextEditingController();
  final portController = TextEditingController();
  final dbNameController = TextEditingController();
  final userController = TextEditingController();
  final passwordController = TextEditingController();
  final ValueNotifier<bool> useSSL = ValueNotifier(false);

  final formKey = GlobalKey<FormState>();

  @override
  State<StatefulWidget> createState() => DbFormState();

  changeConnection(DbClient db) async {
    try{
      await db.disconnect();
      final params = DbConnectionParams(
          nameController.text,
          hostController.text,
          int.parse(portController.text),
          dbNameController.text,
          userController.text,
          passwordController.text,
          useSSL.value);
      await db.setConnectionParams(params);
      await db.connect();
      await db.pullDatabaseModel(); // TODO review that works after last changes in databasebloc
    } on Exception catch (e) {
      throw e;
    }
  }

  void submit(BuildContext context) {
    PostgresClient db = PostgresClient(DbConnectionParams(
        nameController.text,
        hostController.text,
        int.parse(portController.text),
        dbNameController.text,
        userController.text,
        passwordController.text,
        useSSL.value));

    db.databaseBloc.add(ConnectToDatabase(db, context: context, fromForm: true));
  }
}

class DbFormState extends State<DbForm> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Container(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            FormFieldView(Alias(), widget.nameController),
            FormFieldView(Host(), widget.hostController),
            FormFieldView(Port(), widget.portController),
            FormFieldView(DatabaseName(), widget.dbNameController),
            FormFieldView(Username(), widget.userController),
            FormFieldView(Password(), widget.passwordController),
            SwitchListTile(
              title: const Text('SSL'),
              value: widget.useSSL.value,
              onChanged: (value) {
                setState(() {
                  widget.useSSL.value = !widget.useSSL.value;
                });
              },
            )
          ],
        ),
      ),
    );
  }
}
