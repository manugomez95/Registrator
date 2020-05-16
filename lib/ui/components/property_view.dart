import 'package:bitacora/conf/style.dart';
import 'package:bitacora/model/action.dart' as app;
import 'package:bitacora/model/table.dart' as app;
import 'package:bitacora/ui/components/inputs.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bitacora/model/property.dart';
import 'package:tuple/tuple.dart';
import 'package:recase/recase.dart';
import 'package:bitacora/conf/style.dart' as app;

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

/// Last value and current value must be tightly related (to not depend on an index when being an array), this is the best way I could think of
class ValueLV<T> {
  T current;
  final T last;
  FocusNode focus;
  bool firstTime = true;

  ValueLV(this.last, {this.focus});
}

/// keep alive when out of view (to not lose state)
class _PropertyViewState extends State<PropertyView>
    with AutomaticKeepAliveClientMixin {
  List<ValueLV> values = [];

  @override
  void initState() {
    super.initState();
    if (widget.property.type.isArray && widget.property.lastValue != null) {
      final lastValuesList = widget.property.lastValue as List;
      for (var i = 0; i < lastValuesList.length; i++)
        values.add(ValueLV(lastValuesList[i]));
    } else if (widget.property.lastValue != null) {
      values = [ValueLV(widget.property.lastValue)];
    } else
      values = [ValueLV(null)];
  }

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
        generateWidget(widget.property)
      ],
    );
  }

  void _onChangeController(ValueLV value, newValue) {
    setState(() {
      value.current = newValue;
    });
  }

  String _validator(value) {
    if (!widget.property.isNullable && value.isEmpty) {
      return "Field can't be null";
    }
    return null;
  }

  Widget generateWidget(Property property) {
    if (property.type.isArray) {
      return Column(
        children: values
            .asMap()
            .map((i, elem) => MapEntry(
                i,
                Dismissible(
                  child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Expanded(child: buildInput(values[i], property),),
                          Icon(
                            Icons.drag_handle,
                            color: Colors.grey,
                          )
                        ],
                      ),
                  key: ValueKey(values[i]),
                  onDismissed: (direction) {
                    // Remove the item from the data source.
                    setState(() {
                      values.removeAt(i);

                      /// [justification] When last one is removed, there's no build function to update the properties form
                      widget.updater(Tuple2(widget.property,
                          values.map((val) => val.current).toList()));
                    });
                  },
                )))
            .values
            .cast<Widget>()
            .followedBy([
          Row(
            children: <Widget>[
              Spacer(),
              IconButton(
                icon: Icon(
                  Icons.add_circle,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    values.add(ValueLV(null, focus: FocusNode()));
                  });
                },
              ),
              Spacer()
            ],
          ),
        ]).toList(),
      );
    } else {
      return buildInput(values[0], property);
    }
  }

  Widget buildInput(ValueLV value, Property property) {
    Widget ret;

    value.current = value.current == null
        ? ((widget.action.type == app.ActionType.EditLastFrom &&
                value.last != null)
            ? value.last
            : property.type.primitive.defaultV)
        : value.current;

    switch (property.type.primitive) {
      case PrimitiveType.text:
      case PrimitiveType.varchar:

        /// TypeAhead if field references foreign key or enum type
        if (widget.property.foreignKeyOf != null) {
          ret = typeAheadFormField(
              context: context,
              value: value,
              property: property,
              onChanged: (newValue) {
                /// Changing state continuously in this widget results in weird behaviour
                value.current = newValue;
                widget.updater(Tuple2(widget.property, value.current));
              },
              onSuggestionSelected: (suggestion) {
                setState(() {
                  value.current = suggestion;
                });
              },
              validator: _validator);

          /// Normal text field
        } else {
          ret = TextFormField(
              initialValue: value.current,
              keyboardAppearance: Theme.of(context).brightness,
              validator: _validator,
              maxLength: widget.property.charMaxLength,
              textInputAction: TextInputAction.newline,
              minLines: 1,
              maxLines: value.current == "" ? 1 : 5, /// = when showing hint max lines is 1
              keyboardType: TextInputType.multiline,
              focusNode: value.focus,
              onChanged: (newValue) => _onChangeController(value, newValue),
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              decoration: textInputDecoration(value));
        }
        break;

      /// Number field
      case PrimitiveType.integer:
      case PrimitiveType.smallInt:
      case PrimitiveType.bigInt:
      case PrimitiveType.real:
      case PrimitiveType.byteArray:
        ret = TextFormField(
            initialValue: value.current.toString(),
            keyboardAppearance: Theme.of(context).brightness,
            validator: _validator,
            focusNode: value.focus,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.number,
            onChanged: (newValue) => _onChangeController(value, newValue),
            onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
            decoration: InputDecoration(
                hintText: value.last != null ? value.last.toString() : ""));
        break;

      /// Boolean checkbox field
      case PrimitiveType.boolean:
        ret = InkWell(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: Checkbox(
                      value: value.current,
                      focusNode: value.focus,
                      tristate: true,
                      onChanged: (newValue) =>
                          _onChangeController(value, newValue),
                    ),
                  ),
                ),
              ],
            ),
            onTap: () {
              setState(() {
                switch (value.current) {
                  case false:
                    value.current = true;
                    break;
                  case true:
                    value.current = null;
                    break;
                  default:
                    value.current = false;
                    break;
                }
              });
            });
        break;

      /// Timestamp
      case PrimitiveType.timestamp:
        ret = dateTimeField(
            showDate: true,
            showTime: true,
            context: context,
            value: value,
            onChanged: (newValue) => _onChangeController(value, newValue));
        break;

      /// Time
      case PrimitiveType.time:
        ret = dateTimeField(
            showDate: false,
            showTime: true,
            context: context,
            value: value,
            onChanged: (newValue) => _onChangeController(value, newValue));
        break;

      /// Date
      case PrimitiveType.date:
        ret = dateTimeField(
            showDate: true,
            showTime: false,
            context: context,
            value: value,
            onChanged: (newValue) => _onChangeController(value, newValue));
        break;
      default:
        throw Exception("${property.type.primitive} not supported");
    }

    if (widget.property.type.isArray) {
      if (value.focus != null && value.firstTime) {
        FocusScope.of(context).unfocus();
        FocusScope.of(context).requestFocus(value.focus);
      }
      widget.updater(
          Tuple2(widget.property, values.map((val) => val.current).toList()));
    } else
      widget.updater(Tuple2(widget.property, value.current));

    value.firstTime = false;
    return ret;
  }

  @override
  bool get wantKeepAlive => true;
}
