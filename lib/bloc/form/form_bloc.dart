import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:toast/toast.dart';
import './bloc.dart';

class FormBloc extends Bloc<FormEvent, FormState> {
  @override
  FormState get initialState => InitialFormState();

  @override
  Stream<FormState> mapEventToState(
    FormEvent event,
  ) async* {
    if (event is SubmitFormEvent) {
      yield SubmittingFormState();
      // TODO Do something with event.form
      Toast.show("Action done", event.context, duration: Toast.LENGTH_SHORT, gravity:  Toast.BOTTOM);
      yield SubmittedFormState(true);
    }
  }
}
