import 'dart:async';
import 'package:bitacora/model/app_data.dart';
import 'package:bloc/bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:bitacora/ui/components/snack_bars.dart';
import 'package:stack/stack.dart';
import '../../main.dart';
import './bloc.dart';

class FormBloc extends Bloc<FormEvent, PropertiesFormState> {
  Stack<FormEvent> _loadingStack = Stack();

  @override
  PropertiesFormState get initialState => InitialFormState(_loadingStack);

  @override
  Stream<PropertiesFormState> mapEventToState(
    FormEvent event,
  ) async* {
    _loadingStack.push(event);
    yield FormEventLoading(_loadingStack);
    if (event is InsertSubmitForm) {
      try {
        await event.table.client
            .insertRowIntoTable(event.table, event.propertiesForm);
        submitFormSnackBar(event, "${event.action.title} ${event.table.name}",
            undoAction: () { add(DeleteLastEntry(event.table, event.context, rebuildForm: false)); });
      } on Exception catch (e) {
        showErrorSnackBar(event.context, e.toString());
      }
    } else if (event is EditSubmitForm) {
      try {
        await event.table.client
            .editLastFrom(event.table, event.propertiesForm);
        submitFormSnackBar(event, "${event.action.title} ${event.table.name}");
      } on Exception catch (e) {
        showErrorSnackBar(event.context, e.toString());
      }
    } else if (event is DeleteLastEntry) {
      try {
        /// delete last entry and...
        await event.table.client.deleteLastFrom(event.table);

        /// update last row
        await event.table.client.getLastRow(event.table);
        Fluttertoast.showToast(msg: "Removed last row");
      } on Exception catch (e) {
        Fluttertoast.showToast(msg: e.toString().replaceAll("Exception: ", ""));
      }
    }
    _loadingStack.pop();
    if (event is DeleteLastEntry) yield DeleteLastRowState(_loadingStack, rebuildForm: event.rebuildForm);
    else if (event is InsertSubmitForm) yield InsertRowState(_loadingStack);
    else if (event is EditSubmitForm) yield UpdateLastRowState(_loadingStack);
  }
}
