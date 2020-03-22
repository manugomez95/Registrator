import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:registrator/model/property.dart';
import 'package:tuple/tuple.dart';
import 'date_picker.dart';
import 'package:recase/recase.dart';

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
            SizedBox(width: 50),
            Container(
              child: Text(widget.property.type.toString().split(".").last,
                  style: new TextStyle(
                    color: Colors.white,
                    fontSize: 12.0,
                  )),
              decoration: new BoxDecoration(
                  color: Colors.grey[600],
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.circular(5.0))),
              padding:
                  new EdgeInsets.only(left: 4, right: 4, bottom: 2, top: 2),
            )
          ],
        ),
        buildInput(widget.property.type)
      ],
    );
  }

  void _onChangeController(newValue, dataType) {
    setState(() {
      value = newValue;
      updateForm(widget.property.name, widget.property.type, value.toString(),
          widget.updater);
    });
  }

  // TODO shorten
  Widget buildInput(PostgreSQLDataType dataType) {
    Widget ret;
    if ([PostgreSQLDataType.text, PostgreSQLDataType.uuid].contains(dataType)) {
      ret = TextField(
        onChanged: (newValue) => _onChangeController(newValue, dataType),
      );
    } else if ([
      PostgreSQLDataType.real,
      PostgreSQLDataType.smallInteger,
      PostgreSQLDataType.integer,
      PostgreSQLDataType.bigInteger
    ].contains(dataType)) {
      value = value == null ? "" : value;
      ret = TextField(
        keyboardType: TextInputType.number,
        onChanged: (newValue) => _onChangeController(newValue, dataType),
        decoration: new InputDecoration.collapsed(hintText: '0')
      );
    } else if (dataType == PostgreSQLDataType.boolean) {
      value = value == null ? false : value;
      ret = Checkbox(
        value: value,
        onChanged: (newValue) => _onChangeController(newValue, dataType),
      );
    } else if (dataType == PostgreSQLDataType.date) {
      value = value == null ? "2020-03-20" : value;
      ret = DatePicker(showDate: true);
    } else if ([
      PostgreSQLDataType.timestampWithTimezone,
      PostgreSQLDataType.timestampWithoutTimezone
    ].contains(dataType)) {
      value = value == null ? DateTime.now().millisecondsSinceEpoch : value;
      ret = DatePicker(
        showDate: true,
        showTime: true,
      );
    }
    updateForm(widget.property.name, widget.property.type, value.toString(),
        widget.updater);
    return ret;
  }

  @override
  bool get wantKeepAlive => true;
}

void updateForm(String propertyName, PostgreSQLDataType dataType, String value,
    ValueChanged<Tuple2<String, String>> updater) {
  if ([
    PostgreSQLDataType.text,
    PostgreSQLDataType.date,
    PostgreSQLDataType.uuid
  ].contains(dataType)) value = "'$value'";

  updater(Tuple2(propertyName, value));
}
