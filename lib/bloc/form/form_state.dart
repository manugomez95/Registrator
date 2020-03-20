import 'package:equatable/equatable.dart';

abstract class FormState extends Equatable {
  const FormState();
}

class InitialFormState extends FormState {
  @override
  List<Object> get props => [];
}

class SubmittingFormState extends FormState {
  @override
  List<Object> get props => [];
}

class SubmittedFormState extends FormState {
  final bool success;

  SubmittedFormState(this.success);

  @override
  List<Object> get props => [success];
}