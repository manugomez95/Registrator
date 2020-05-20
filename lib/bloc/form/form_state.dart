import 'dart:math';

import 'package:bitacora/bloc/form/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:stack/stack.dart';

abstract class PropertiesFormState extends Equatable {
  final bool rebuildForm;
  final Stack<FormEvent> loadingStack;

  const PropertiesFormState(this.rebuildForm, this.loadingStack);
}

class InitialFormState extends PropertiesFormState {
  InitialFormState(Stack<FormEvent> loadingStack) : super(false, loadingStack);

  @override
  List<Object> get props => [];
}

/// It seems to not be used but it actually updates the form when yielded
class DeleteLastRowState extends PropertiesFormState {
  final int id = Random().nextInt(100000);

  DeleteLastRowState(Stack<FormEvent> loadingStack, {bool rebuildForm}) : super(rebuildForm, loadingStack);

  @override
  List<Object> get props => [id];
}

/// It seems to not be used but it actually updates the form when yielded
class InsertRowState extends PropertiesFormState {
  final int id = Random().nextInt(100000);

  InsertRowState(Stack<FormEvent> loadingStack) : super(false, loadingStack);

  @override
  List<Object> get props => [id];
}

/// It seems to not be used but it actually updates the form when yielded
class UpdateLastRowState extends PropertiesFormState {
  final int id = Random().nextInt(100000);

  UpdateLastRowState(Stack<FormEvent> loadingStack) : super(false, loadingStack);

  @override
  List<Object> get props => [id];
}

class FormEventLoading extends PropertiesFormState {
  final int id = Random().nextInt(100000);

  FormEventLoading(Stack<FormEvent> loadingStack) : super(false, loadingStack);

  @override
  List<Object> get props => [id];
}

// TODO when refresh form, change action, etc... Might have to move the form bloc up in the widget tree