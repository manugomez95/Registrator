import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:bitacora/model/action.dart' as app;
import 'package:bitacora/model/table.dart' as app;
import 'package:bitacora/ui/pages/actions_page.dart';

abstract class FormEvent extends Equatable {
  const FormEvent();
}

class SubmitFormEvent extends FormEvent {
  final Map<String, String> propertiesForm;
  final app.Action action;
  final app.Table table;
  final BuildContext context;

  SubmitFormEvent(this.context, this.propertiesForm, this.action, this.table);

  @override
  List<Object> get props => [propertiesForm, action, table];
}