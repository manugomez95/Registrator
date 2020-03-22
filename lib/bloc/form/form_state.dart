import 'package:equatable/equatable.dart';

abstract class PropertiesFormState extends Equatable {
  const PropertiesFormState();
}

class InitialFormState extends PropertiesFormState {
  @override
  List<Object> get props => [];
}

class SubmittingFormState extends PropertiesFormState {
  @override
  List<Object> get props => [];
}

class SubmittedFormState extends PropertiesFormState {
  final bool success;

  SubmittedFormState(this.success);

  @override
  List<Object> get props => [success];
}