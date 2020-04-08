import 'package:bitacora/bloc/form/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void showErrorSnackBar(BuildContext context, String message) {
  final snackBar = SnackBar(
    content: Text(message),
    backgroundColor: Colors.red,
  );
  Scaffold.of(context).showSnackBar(snackBar);
}

void submitFormSnackBar(SubmitFormEvent event, String message,
    {Function undoAction}) {
  final snackBar = SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: "Undo",
        onPressed: () {
          undoAction();
        },
      ));

  Scaffold.of(event.context).showSnackBar(snackBar);
}
