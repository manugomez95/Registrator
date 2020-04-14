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
        } on PostgreSQLException catch (e) {
          showErrorSnackBar(event.context, e.toString());
        }
      } else if (event.action.type == ActionType.EditLastFrom) {
        await event.table.client.updateLastRow(
            event.table, event.propertiesForm);
        submitFormSnackBar(
            event, "${event.action.title} ${event.table.name}",
            undoAction: event.undo);
      }
    }
    else if (event is DeleteLastEntry) {
      try {
        await event.table.client.removeLastEntry(event.table);
        Fluttertoast.showToast(msg: "Removed last row");
        yield DeletedLastRow();
      } on Exception catch (e) {
        Fluttertoast.showToast(msg: e.toString());
      }
    }
  }
}