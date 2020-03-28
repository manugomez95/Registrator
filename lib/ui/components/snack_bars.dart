import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// TODO maybe useful in the future
enum SnackBarType {
  ERROR
}

void showErrorSnackBar(BuildContext context, String message) {
  final snackBar = SnackBar(
    content: Text(message),
    backgroundColor: Colors.red,
  );
  Scaffold.of(context).showSnackBar(snackBar);
}