import 'package:bitacora/utils/db_parameter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FormFieldView<T> extends StatefulWidget {
  FormFieldView(this.param, this.controller);

  final DbParameter param;
  final ValueNotifier controller;

  @override
  State<StatefulWidget> createState() => _FormFieldViewState();
}

/// keep alive when out of view (to not lose state)
class _FormFieldViewState extends State<FormFieldView>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    super.build(context);
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
              controller: widget.controller,
              validator: validator,
              textInputAction: TextInputAction.next,
              keyboardType:
              widget.param is Port ? TextInputType.number : TextInputType.text,
              onFieldSubmitted: (v) {
                FocusScope.of(context).nextFocus();
              },
              obscureText: widget.param is Password ? true : false,
              decoration: InputDecoration(
                hintText: widget.param.defaultValue.toString(),
                labelText: widget.param.title,
              ))
        ],
    );
  }

  @override
  bool get wantKeepAlive => true;

  String validator(value) {
    if (value.isEmpty) {
      return "Field can't be null";
    }
    return null;
  }
}
