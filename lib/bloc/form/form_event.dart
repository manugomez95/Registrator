import 'package:bitacora/model/property.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class FormEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class SubmitFormEvent extends FormEvent {
  final BuildContext context;
  final app.Table table;
  final Map<Property, dynamic> propertiesForm;

  SubmitFormEvent(
    this.context,
    this.table,
    this.propertiesForm,
  );

  @override
  List<Object> get props => [table, propertiesForm];
}

class EditFormEvent extends FormEvent {
  final BuildContext context;
  final app.Table table;
  final Map<Property, dynamic> propertiesForm;

  EditFormEvent(
    this.context,
    this.table,
    this.propertiesForm,
  );

  @override
  List<Object> get props => [table, propertiesForm];
}

class DeleteFormEvent extends FormEvent {
  final BuildContext context;
  final app.Table table;

  DeleteFormEvent(
    this.context,
    this.table,
  );

  @override
  List<Object> get props => [table];
}