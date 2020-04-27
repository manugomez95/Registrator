import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:bitacora/ui/components/snack_bars.dart';
import './bloc.dart';

class FormBloc extends Bloc<FormEvent, PropertiesFormState> {
  @override
  PropertiesFormState get initialState => InitialFormState();

  @override
  Stream<PropertiesFormState> mapEventToState(FormEvent event,) async* {
      if (event is InsertSubmitForm) {
        try {
          await event.table.client.insertRowIntoTable(
              event.table, event.propertiesForm);
          submitFormSnackBar(
              event, "${event.action.title} ${event.table.name}",
              undoAction: event.undo);
        } on Exception catch (e) {
          showErrorSnackBar(event.context, e.toString());
        }
      } else if (event is EditSubmitForm) {
        try {
          await event.table.client.editLastFrom(
              event.table, event.propertiesForm);
          submitFormSnackBar(
              event, "${event.action.title} ${event.table.name}");
        } on Exception catch (e) {
          showErrorSnackBar(event.context, e.toString());
        }
      }
    else if (event is DeleteLastEntry) {
      try {
        /// delete last entry and...
        await event.table.client.deleteLastFrom(event.table);
        /// update last row
        await event.table.client.getLastRow(event.table);
        Fluttertoast.showToast(msg: "Removed last row");
        yield DeletedLastRow();
      } on Exception catch (e) {
        Fluttertoast.showToast(msg: e.toString());
      }
    }
  }
}