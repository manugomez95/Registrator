import 'package:flutter/material.dart';
import 'package:bitacora/conf/style.dart';

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
            child: Text('CANCEL', style: Theme.of(context).textTheme.button.copyWith(color: Theme.of(context).colorScheme.defaultTextColor),),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          FlatButton(
            child: Text('ACCEPT', style: Theme.of(context).textTheme.button.copyWith(color: Theme.of(context).colorScheme.defaultTextColor)),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          )
        ],
      );
    },
  );
}