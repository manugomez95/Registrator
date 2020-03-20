import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:registrator/ui/tabs/actionsPage.dart';

abstract class FormEvent extends Equatable {
  const FormEvent();
}

class SubmitFormEvent extends FormEvent {
  final PropertiesForm form;
  final BuildContext context;

  SubmitFormEvent(this.context, this.form);

  @override
  List<Object> get props => [form];
}