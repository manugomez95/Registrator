import 'package:bitacora/bloc/form/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void showSnackBar(
  BuildContext context,
  String message, {
  required Function? undoAction,
}) {
  final snackBar = SnackBar(
    content: Text(message),
    action: undoAction != null
        ? SnackBarAction(
            label: 'Undo',
            onPressed: () => undoAction(),
          )
        : null,
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

void showErrorSnackBar(BuildContext context, String message) {
  final snackBar = SnackBar(
    content: Text(message),
    backgroundColor: Theme.of(context).colorScheme.error,
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
