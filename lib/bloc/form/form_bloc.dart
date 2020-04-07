import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:bitacora/model/action.dart';
import 'package:bitacora/ui/components/snack_bars.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FormBloc extends Bloc<FormEvent, PropertiesFormState> {
  @override
  PropertiesFormState get initialState => InitialFormState();

  @override
  Stream<PropertiesFormState> mapEventToState(
    FormEvent event,
  ) async* {
    if (event is SubmitFormEvent) {
      yield SubmittingFormState();
      if (event.action.type == ActionType.InsertInto) {
        try {
          await event.table.client.insertRowIntoTable(event.table.name, event.propertiesForm);
          final snackBar = SnackBar(
              content: Text("${event.action.title} ${event.table.name} done!"),
              action: SnackBarAction(
                label: "Undo",
                onPressed: () async {
                  try {
                    await event.table.client.cancelLastInsertion(
                        event.table.name, event.propertiesForm);
                    Fluttertoast.showToast(msg: "Undo");
                  } on PostgreSQLException catch (e) {
                    showErrorSnackBar(event.context, e.toString());
                  }
                },
              ));

          Scaffold.of(event.context).showSnackBar(snackBar);

          // TODO wtf is this obtain shared preferences
          final prefs = await SharedPreferences.getInstance();
          // set value
          prefs.setString('last_table', event.table.name);

          yield SubmittedFormState(true);
        } on PostgreSQLException catch (e) {
          showErrorSnackBar(event.context, e.toString());
        }
      } else if (event.action.type == ActionType.EditLastFrom) {
        await event.table.client.updateLastRow(event.table, event.propertiesForm);
        // TODO make it a function
        final snackBar = SnackBar(
            content: Text("${event.action.title} ${event.table.name} done!"),
            action: SnackBarAction(
              label: "Undo",
              onPressed: () async {
                try {
                  // TODO Cancel last edition
                  await event.table.client.cancelLastInsertion(
                      event.table.name, event.propertiesForm);
                  Fluttertoast.showToast(msg: "Undo");
                } on PostgreSQLException catch (e) {
                  showErrorSnackBar(event.context, e.toString());
                }
              },
            ));

        Scaffold.of(event.context).showSnackBar(snackBar);
      } else {
        showErrorSnackBar(event.context, "Sorry, not implemented yet!");
      }
    }
  }
}
