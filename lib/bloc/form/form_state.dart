import 'package:equatable/equatable.dart';

abstract class PropertiesFormState extends Equatable {
  @override
  List<Object> get props => [];
}

class InitialFormState extends PropertiesFormState {}

class LoadingState extends PropertiesFormState {}

class ErrorState extends PropertiesFormState {}

class SubmitSuccessState extends PropertiesFormState {}

class EditSuccessState extends PropertiesFormState {}

class DeleteSuccessState extends PropertiesFormState {}