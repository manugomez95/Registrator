import 'package:bitacora/conf/style.dart';
import 'package:bitacora/model/action.dart' as app;
import 'package:bitacora/model/table.dart' as app;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:postgres/postgres.dart';
import 'package:bitacora/model/property.dart';
import 'package:tuple/tuple.dart';
import 'package:recase/recase.dart';
import 'package:bitacora/conf/style.dart' as app;
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';

class PropertyView extends StatefulWidget {
  PropertyView(this.property, this.updater, this.action, {this.definesOrder});

  final Property property;
  final app.Action action;
  final bool definesOrder;

  /// useful to pass info to parent
  final ValueChanged<Tuple2<Property, dynamic>> updater;

  @override
  State<StatefulWidget> createState() => _PropertyViewState();
}

/// keep alive when out of view (to not lose state)
class _PropertyViewState extends State<PropertyView>
    with AutomaticKeepAliveClientMixin {
  var value;
  bool first = true;

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              ReCase(widget.property.name).sentenceCase,
              style: new TextStyle(
                color: theme.colorScheme.defaultTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 19.0,
              ),
            ),
            SizedBox(width: 35),
            Container(
              child: Text(widget.property.type.alias,
                  style: new TextStyle(
                    color: theme.colorScheme.negativeDefaultTxtColor,
                    fontSize: 12.0,
                  )),
              decoration: new BoxDecoration(
                  color: widget.definesOrder
                      ? theme.colorScheme.auto
                      : theme.colorScheme.typeBoxColor,
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

  void _onChangeController(newValue) {
    setState(() {
      value = newValue;
    });
  }

  // TODO shorten
  Widget buildInput(Property property) {
    Widget ret;
    // TODO switch case might be cooler
    if (property.foreignKeyOf != null &&
        [PostgreSQLDataType.text].contains(property.type.complete)) {
      value = value == null
          ? (widget.action.type == app.ActionType.EditLastFrom
              ? property.lastValue
              : "")
          : value;
      ret = TypeAheadFormField(
        textFieldConfiguration: TextFieldConfiguration(
            controller: TextEditingController(text: value),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            decoration: InputDecoration(
                hintText: property.lastValue != null
                    ? (property.lastValue.toString().length > 40
                        ? "${property.lastValue.toString().substring(0, 40)}..."
                        : property.lastValue.toString())
                    : "Lorem ipsum...")),
        suggestionsCallback: (pattern) {
          return property.foreignKeyOf.client
              .getPkDistinctValues(property.foreignKeyOf, pattern: pattern);
        },
        itemBuilder: (context, suggestion) {
          return ListTile(
            title: Text(suggestion),
          );
        },
        hideOnEmpty: true,
        transitionBuilder: (context, suggestionsBox, controller) {
          return suggestionsBox;
        },
        onSuggestionSelected: (suggestion) {
          setState(() {
            value = suggestion;
          });
        },
        validator: (value) {
          if (!property.isNullable && value.isEmpty) {
            return "Field can't be null";
          }
          return null;
        },
      );
    } else if ([PostgreSQLDataType.text].contains(property.type.complete)) {
      value = value == null
          ? (widget.action.type == app.ActionType.EditLastFrom
              ? property.lastValue
              : value)
          : value;
      ret = TextFormField(
          keyboardAppearance: Theme.of(context).brightness,
          initialValue: value,
          validator: (value) {
            if (!property.isNullable && value.isEmpty) {
              return "Field can't be null";
            }
            return null;
          },
          maxLength: property.charMaxLength,
          textInputAction: TextInputAction.newline,
          minLines: 1,
          maxLines: 5,
          keyboardType: TextInputType.multiline,
          onChanged: (newValue) => _onChangeController(newValue),
          onFieldSubmitted: (v) {
            FocusScope.of(context).nextFocus();
          },
          decoration: InputDecoration(
              hintText: property.lastValue != null
                  ? (property.lastValue.toString().length > 40
                      ? "${property.lastValue.toString().substring(0, 40)}..."
                      : property.lastValue.toString())
                  : "Lorem ipsum..."));
    } else if ([
      PostgreSQLDataType.real,
      PostgreSQLDataType.smallInteger,
      PostgreSQLDataType.integer,
      PostgreSQLDataType.bigInteger,
      PostgreSQLDataType.byteArray
    ].contains(property.type.complete)) {
      value = value == null
          ? ((widget.action.type == app.ActionType.EditLastFrom &&
                  property.lastValue != null)
              ? property.lastValue.toString()
              : value)
          : value;
      ret = TextFormField(
          keyboardAppearance: Theme.of(context).brightness,
          initialValue: value,
          validator: (value) {
            if (!property.isNullable && value.isEmpty) {
              return "Field can't be null";
            }
            return null;
          },
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.number,
          onChanged: (newValue) => _onChangeController(newValue),
          onFieldSubmitted: (v) {
            FocusScope.of(context).nextFocus();
          },
          decoration: InputDecoration(
              hintText: property.lastValue != null
                  ? property.lastValue.toString()
                  : "0"));
    } else if (property.type.complete == PostgreSQLDataType.boolean) {
      value = value == null ? false : value;
      ret = Checkbox(
        value: value,
        onChanged: (newValue) => _onChangeController(newValue),
      );
    } else if (property.type.complete == PostgreSQLDataType.date) {
      DateFormat format = DateFormat("yyyy-MM-dd");
      value = first
          ? (widget.action.type == app.ActionType.EditLastFrom
              ? property.lastValue
              : DateTime.now())
          : value;
      first = false;
      ret = DateTimeField(
        initialValue: value,
        onChanged: _onChangeController,
        format: format,
        decoration: InputDecoration(
            hintText: property.lastValue != null
                ? format.format(property.lastValue)
                : format.format(DateTime.now())),
        onShowPicker: (context, currentValue) {
          return showDatePicker(
              context: context,
              firstDate: DateTime(1900),
              initialDate: currentValue ?? DateTime.now(),
              lastDate: DateTime(2100));
        },
      );
    } else if ([
      PostgreSQLDataType.timestampWithTimezone,
      PostgreSQLDataType.timestampWithoutTimezone
    ].contains(property.type.complete)) {
      DateFormat format = DateFormat("yyyy-MM-dd HH:mm");
      value = first
          ? (widget.action.type == app.ActionType.EditLastFrom
              ? property.lastValue
              : DateTime.now())
          : value;
      first = false;
      ret = DateTimeField(
        initialValue: value,
        onChanged: _onChangeController,
        format: format,
        decoration: InputDecoration(
            hintText: property.lastValue != null
                ? format.format(property.lastValue)
                : format.format(DateTime.now())),
        onShowPicker: (context, currentValue) async {
          final date = await showDatePicker(
              context: context,
              firstDate: DateTime(1900),
              initialDate: currentValue ?? DateTime.now(),
              lastDate: DateTime(2100));
          if (date != null) {
            final time = await showTimePicker(
              context: context,
              initialTime:
                  TimeOfDay.fromDateTime(currentValue ?? DateTime.now()),
            );
            return DateTimeField.combine(date, time);
          } else {
            return currentValue;
          }
        },
      );
    }
    widget.updater(Tuple2(property, value));
    return ret;
  }

  @override
  bool get wantKeepAlive => true;
}
