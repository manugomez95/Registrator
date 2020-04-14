import 'package:flutter/material.dart';

Future<bool> asyncConfirmDialog(BuildContext context, {String title: "", String message: ""}) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // user must tap button for close dialog!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          FlatButton(
            child: const Text('CANCEL'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          FlatButton(
            child: const Text('ACCEPT'),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          )
        ],
      );
    },
  );
}