import 'dart:async';
import 'package:bitacora/model/app_data.dart';
import 'package:bloc/bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:bitacora/ui/components/snack_bars.dart';
import 'package:stack/stack.dart';
import '../../main.dart';
import './bloc.dart';

class FormBloc extends Bloc<FormEvent, PropertiesFormState> {
  FormBloc() : super(InitialFormState()) {
    on<SubmitFormEvent>(_onSubmitForm);
    on<EditFormEvent>(_onEditForm);
    on<DeleteFormEvent>(_onDeleteForm);
  }

  Future<void> _onSubmitForm(
    SubmitFormEvent event,
    Emitter<PropertiesFormState> emit,
  ) async {
    emit(LoadingState());
    try {
      print("Submitting form data:");
      print("Table: ${event.table.name}");
      print("Properties form data:");
      event.propertiesForm.forEach((property, value) {
        print("  ${property.name}: $value (${value?.runtimeType})");
      });

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
      emit(InitialFormState());
    } catch (e, stackTrace) {
      print("Error submitting form: $e");
      print("Stack trace: $stackTrace");
      showErrorSnackBar(event.context, e.toString());
      emit(ErrorState());
    }
  }

  Future<void> _onEditForm(
    EditFormEvent event,
    Emitter<PropertiesFormState> emit,
  ) async {
    emit(LoadingState());
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
      emit(InitialFormState());
    } catch (e) {
      showErrorSnackBar(event.context, e.toString());
      emit(ErrorState());
    }
  }

  Future<void> _onDeleteForm(
    DeleteFormEvent event,
    Emitter<PropertiesFormState> emit,
  ) async {
    emit(LoadingState());
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
      emit(InitialFormState());
    } catch (e) {
      showErrorSnackBar(event.context, e.toString());
      emit(ErrorState());
    }
  }
}
