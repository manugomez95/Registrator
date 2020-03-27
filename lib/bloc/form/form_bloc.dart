import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:registrator/dbClients/postgres_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      if (event.action == "INSERT INTO") {
        try {
          await getIt<PostgresClient>()
              .insertRowIntoTable(event.table.name, event.propertiesForm);
          final snackBar = SnackBar(
              content: Text("${event.action} ${event.table.name} done!"),
              action: SnackBarAction(
                label: "Undo",
                onPressed: () {
                  // Some code to undo the change.
                },
              ));

          Scaffold.of(event.context).showSnackBar(snackBar);

          // obtain shared preferences
          final prefs = await SharedPreferences.getInstance();
          // set value
          prefs.setString('last_table', event.table.name);

          yield SubmittedFormState(true);
        } on PostgreSQLException catch (e) {
          final snackBar = SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          );
          Scaffold.of(event.context).showSnackBar(snackBar);
          // TODO abstract error snackbar
        }
      }
      else {
        final snackBar = SnackBar(
          content: Text("Sorry, not implemented yet!"),
          backgroundColor: Colors.red,
        );
        Scaffold.of(event.context).showSnackBar(snackBar);
      }
    }
  }
}
