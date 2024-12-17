import 'dart:async';
import 'package:bitacora/model/app_data.dart';
import 'package:bloc/bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:bitacora/ui/components/snack_bars.dart';
import 'package:stack/stack.dart';
import '../../main.dart';
import './bloc.dart';

class FormBloc extends Bloc<FormEvent, PropertiesFormState> {
  FormBloc() : super(InitialFormState());

  @override
  Stream<PropertiesFormState> mapEventToState(FormEvent event) async* {
    if (event is SubmitFormEvent) {
      yield LoadingState();
      try {
        final success = await event.table.client
            .insertRowIntoTable(event.table, event.propertiesForm);
        if (success) {
          await event.table.client.getLastRow(event.table);
          showSnackBar(
            event.context,
            "${event.action.title} ${event.table.name}",
            undoAction: null,
          );
        }
        yield SubmitSuccessState();
      } catch (e) {
        showErrorSnackBar(event.context, e.toString());
        yield ErrorState();
      }
    } else if (event is EditFormEvent) {
      yield LoadingState();
      try {
        final success = await event.table.client
            .editLastFrom(event.table, event.propertiesForm);
        if (success) {
          await event.table.client.getLastRow(event.table);
          showSnackBar(
            event.context,
            "${event.action.title} ${event.table.name}",
            undoAction: null,
          );
        }
        yield EditSuccessState();
      } catch (e) {
        showErrorSnackBar(event.context, e.toString());
        yield ErrorState();
      }
    } else if (event is DeleteFormEvent) {
      yield LoadingState();
      try {
        final success = await event.table.client.deleteLastFrom(event.table);
        if (success) {
          await event.table.client.getLastRow(event.table);
          showSnackBar(
            event.context,
            "${event.action.title} ${event.table.name}",
            undoAction: null,
          );
        }
        yield DeleteSuccessState();
      } catch (e) {
        showErrorSnackBar(event.context, e.toString());
        yield ErrorState();
      }
    }
  }
}
