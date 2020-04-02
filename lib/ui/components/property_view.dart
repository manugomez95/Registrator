import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:bitacora/model/property.dart';
import 'package:tuple/tuple.dart';
import 'date_picker.dart';
import 'package:recase/recase.dart';
import 'package:bitacora/conf/style.dart' as app;

class PropertyView extends StatefulWidget {
  PropertyView(this.property, this.updater);

  final Property property;

  /// useful to pass info to parent
  final ValueChanged<Tuple2<String, String>> updater;

  @override
  State<StatefulWidget> createState() => _PropertyViewState();
}

/// keep alive when out of view (to not lose state)
class _PropertyViewState extends State<PropertyView>
    with AutomaticKeepAliveClientMixin {
  var value;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              ReCase(widget.property.name).sentenceCase,
              style: new TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 19.0,
              ),
            ),
            SizedBox(width: 35),
            Container(
              child: Text(widget.property.type.toString().split(".").last,
                  style: new TextStyle(
                    color: Colors.white,
                    fontSize: 12.0,
                  )),
              decoration: new BoxDecoration(
                  color: app.Style.grey,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.circular(5.0))),
              padding:
                  new EdgeInsets.only(left: 4, right: 4, bottom: 2, top: 2),
            )
          ],
        ),
        buildInput(widget.property)
      ],
    );
  }

  void _onChangeController(newValue, dataType) {
    setState(() {
      value = newValue;
      updateForm(
          widget.property.name, widget.property.type, value, widget.updater);
    });
  }

  // TODO shorten
  Widget buildInput(Property property) {
    Widget ret;
    if ([PostgreSQLDataType.text].contains(property.type)) {
      ret = TextFormField(
          validator: (value) {
            if (!property.isNullable && value.isEmpty) {
              return "Field can't be null";
            }
            return null;
          },
          maxLength: property.charMaxLength,
          textInputAction: TextInputAction.next,
          onChanged: (newValue) => _onChangeController(newValue, property.type),
          onFieldSubmitted: (v) {
            FocusScope.of(context).nextFocus();
          },
          decoration: new InputDecoration.collapsed(
              hintText: 'Lorem Ipsum...'));
    } else if ([
      PostgreSQLDataType.real,
      PostgreSQLDataType.smallInteger,
      PostgreSQLDataType.integer,
      PostgreSQLDataType.bigInteger,
      PostgreSQLDataType.uuid
    ].contains(property.type)) {
      ret = TextFormField(
          validator: (value) {
            if (!property.isNullable && value.isEmpty) {
              return "Field can't be null";
            }
            return null;
          },
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.number,
          onChanged: (newValue) => _onChangeController(newValue, property.type),
          onFieldSubmitted: (v) {
            FocusScope.of(context).nextFocus();
          },
          decoration: new InputDecoration.collapsed(hintText: '0'));
    } else if (property.type == PostgreSQLDataType.boolean) {
      value = value == null ? false : value;
      ret = Checkbox(
        value: value,
        onChanged: (newValue) => _onChangeController(newValue, property.type),
      );
    } else if (property.type == PostgreSQLDataType.date) {
      value = value == null ? "2020-03-20" : value; // TODO correct
      ret = DatePicker(showDate: true);
    } else if ([
      PostgreSQLDataType.timestampWithTimezone,
      PostgreSQLDataType.timestampWithoutTimezone
    ].contains(property.type)) {
      value = value == null ? "'${DateTime.now()}'" : value; // TODO correct
      ret = DatePicker(
        showDate: true,
        showTime: true,
      );
    }
    updateForm(
        widget.property.name, widget.property.type, value, widget.updater);
    return ret;
  }

  @override
  bool get wantKeepAlive => true;
}

/// What happens with null? Generated "null" string
void updateForm(String propertyName, PostgreSQLDataType dataType, value,
    ValueChanged<Tuple2<String, String>> updater) {
  if ([
        PostgreSQLDataType.text,
        PostgreSQLDataType.date,
      ].contains(dataType) &&
      value != null) value = "'${value.toString()}'";

  updater(Tuple2(propertyName, value.toString()));
}
