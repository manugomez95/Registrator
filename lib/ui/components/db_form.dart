import 'package:bitacora/bloc/database_model/db_model_bloc.dart';
import 'package:bitacora/bloc/database_model/db_model_event.dart';
import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
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

  void submit(BuildContext context) {
    DbDescription db = PostgreSQL(
        nameController.text,
        hostController.text,
        int.parse(portController.text),
        dbNameController.text,
        userController.text,
        passwordController.text,
        useSSL.value);
    getIt<DatabaseModelBloc>()
        .add(ConnectToDatabase(PostgresClient(db), context: context, fromForm: true));
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
