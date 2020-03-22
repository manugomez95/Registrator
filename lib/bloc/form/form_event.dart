import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:registrator/model/table.dart' as my;
import 'package:registrator/ui/pages/actionsPage.dart';

abstract class FormEvent extends Equatable {
  const FormEvent();
}

class SubmitFormEvent extends FormEvent {
  final Map<String, String> propertiesForm;
  final String action;
  final my.Table table;
  final BuildContext context;

  SubmitFormEvent(this.context, this.propertiesForm, this.action, this.table);

  @override
  List<Object> get props => [propertiesForm, action, table];
}