import 'package:bitacora/bloc/database_model/db_model_bloc.dart';
import 'package:bitacora/bloc/database_model/db_model_event.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import 'form_field_view.dart';

class DbForm extends StatelessWidget {
  final hostController = TextEditingController();
  final portController = TextEditingController();
  final dbNameController = TextEditingController();
  final userController = TextEditingController();
  final passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Container(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            FormFieldView(Host(), hostController),
            FormFieldView(Port(), portController),
            FormFieldView(DatabaseName(), dbNameController),
            FormFieldView(Username(), userController),
            FormFieldView(Password(), passwordController),
          ],
        ),
      ),
    );
  }

  void submit(BuildContext context) {
    getIt<DatabaseModelBloc>().add(ConnectToDatabase(
        hostController.text,
        int.parse(portController.text),
        dbNameController.text,
        userController.text,
        passwordController.text,
        context: context,
        fromForm: true));
  }
}
