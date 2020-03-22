import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:registrator/dbClients/postgres_client.dart';
import '../../main.dart';
import './bloc.dart';

class FormBloc extends Bloc<FormEvent, PropertiesFormState> {
  @override
  PropertiesFormState get initialState => InitialFormState();

  @override
  Stream<PropertiesFormState> mapEventToState(
    FormEvent event,
  ) async* {
    if (event is SubmitFormEvent) {
      yield SubmittingFormState();
      // TODO change by action class or enum
      if (event.action == "INSERT INTO") if (await getIt<PostgresClient>()
          .insertRowIntoTable(event.table.name, event.propertiesForm)) {
        final snackBar = SnackBar(
            content: Text("${event.action} ${event.table.name} done!"),
            action: SnackBarAction(
              label: "Undo",
              onPressed: () {
                // Some code to undo the change.
              },
            ));
        Scaffold.of(event.context).showSnackBar(snackBar);
      } else {
        yield SubmittedFormState(true);
      }
    }
  }
}
