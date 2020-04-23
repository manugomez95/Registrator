import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:postgres/postgres.dart';
import 'package:bitacora/model/action.dart';
import 'package:bitacora/ui/components/snack_bars.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './bloc.dart';

class FormBloc extends Bloc<FormEvent, PropertiesFormState> {
  @override
  PropertiesFormState get initialState => InitialFormState();

  @override
  Stream<PropertiesFormState> mapEventToState(FormEvent event,) async* {
    if (event is SubmitFormEvent) {
      if (event.action.type == ActionType.InsertInto) {
        try {
          await event.table.client.insertRowIntoTable(
              event.table, event.propertiesForm);
          submitFormSnackBar(
              event, "${event.action.title} ${event.table.name}",
              undoAction: event.undo);

          // TODO wtf is this obtain shared preferences
          final prefs = await SharedPreferences.getInstance();
          // set value
          prefs.setString('last_table', event.table.name);

        } on Exception catch (e) {
          showErrorSnackBar(event.context, e.toString());
        }
      } else if (event.action.type == ActionType.EditLastFrom) {
        try {
          await event.table.client.editLastFrom(
              event.table, event.propertiesForm);
          submitFormSnackBar(
              event, "${event.action.title} ${event.table.name}",
              undoAction: event.undo);
        } on Exception catch (e) {
          showErrorSnackBar(event.context, e.toString());
        }
      }
    }
    else if (event is DeleteLastEntry) {
      try {
        /// delete last entry and...
        await event.table.client.deleteLastFrom(event.table);
        /// update last row
        await event.table.client.getLastRow(event.table);
        Fluttertoast.showToast(msg: "Removed last row");
        yield DeletedLastRow(); // TODO use this
      } on Exception catch (e) {
        Fluttertoast.showToast(msg: e.toString());
      }
    }
  }
}