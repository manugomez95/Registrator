import 'package:bitacora/model/property.dart';
import 'package:bitacora/ui/components/snack_bars.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:bitacora/model/action.dart' as app;
import 'package:bitacora/model/table.dart' as app;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:postgres/postgres.dart';

abstract class FormEvent extends Equatable {
  final app.Table table;
  final BuildContext context;

  const FormEvent(this.table, this.context);

  @override
  List<Object> get props => [table, context];
}

abstract class SubmitFormEvent extends FormEvent {
  final Map<Property, dynamic> propertiesForm;
  final app.Action action;

  SubmitFormEvent(context, this.propertiesForm, this.action, table) : super(table, context);

  @override
  List<Object> get props => [propertiesForm, action, table];
}

class InsertSubmitForm extends SubmitFormEvent {
  InsertSubmitForm(BuildContext context, Map<Property, dynamic> propertiesForm, app.Action action, app.Table table) : super(context, propertiesForm, action, table);

  Future<void> undo() async {
    try {
      await table.client.cancelLastInsertion(
          table, propertiesForm);
      await table.client.getLastRow(table);
      Fluttertoast.showToast(msg: "Undo");
    } on PostgreSQLException catch (e) {
      showErrorSnackBar(context, e.toString());
    }
  }
}

class EditSubmitForm extends SubmitFormEvent {
  EditSubmitForm(BuildContext context, Map<Property, dynamic> propertiesForm, app.Action action, app.Table table) : super(context, propertiesForm, action, table);
}

class DeleteLastEntry extends FormEvent {
  DeleteLastEntry(app.Table table, BuildContext context) : super(table, context);
}