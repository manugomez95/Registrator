import 'package:bitacora/ui/components/snack_bars.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:bitacora/model/action.dart' as app;
import 'package:bitacora/model/table.dart' as app;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:postgres/postgres.dart';

abstract class FormEvent extends Equatable {
  const FormEvent();
}

abstract class SubmitFormEvent extends FormEvent {
  final Map<String, String> propertiesForm;
  final app.Action action;
  final app.Table table;
  final BuildContext context;

  SubmitFormEvent(this.context, this.propertiesForm, this.action, this.table);

  @override
  List<Object> get props => [propertiesForm, action, table];

  void undo();
}

class InsertSubmitForm extends SubmitFormEvent {
  InsertSubmitForm(BuildContext context, Map<String, String> propertiesForm, app.Action action, app.Table table) : super(context, propertiesForm, action, table);

  @override
  Future<void> undo() async {
    try {
      await table.client.cancelLastInsertion(
          table, propertiesForm);
      Fluttertoast.showToast(msg: "Undo");
    } on PostgreSQLException catch (e) {
      showErrorSnackBar(context, e.toString());
    }
  }
}

class EditSubmitForm extends SubmitFormEvent {
  EditSubmitForm(BuildContext context, Map<String, String> propertiesForm, app.Action action, app.Table table) : super(context, propertiesForm, action, table);

  @override
  Future<void> undo() async {
    try {
      // TODO Cancel last update instead of insertion
      await table.client.cancelLastInsertion(
          table, propertiesForm);
      Fluttertoast.showToast(msg: "Undo");
    } on PostgreSQLException catch (e) {
      showErrorSnackBar(context, e.toString());
    }
  }

}