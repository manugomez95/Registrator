import 'package:bitacora/model/action.dart' as app;
import 'package:bitacora/model/property.dart';
import 'package:bitacora/ui/components/property_view.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';

TypeAheadFormField typeAheadFormField(
    {BuildContext context,
    Property property,
    ValueLV value,
    Function(dynamic) onSuggestionSelected,
    Function(dynamic) onChanged,
    Function(String) validator}) {
  return TypeAheadFormField(
    textFieldConfiguration: TextFieldConfiguration(
        controller: TextEditingController(text: value.current),
        keyboardAppearance: Theme.of(context).brightness,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
        onChanged: onChanged,
        focusNode: value.focus,
        decoration: textInputDecoration(value)),
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
    onSuggestionSelected: onSuggestionSelected,
    validator: validator,
  );
}

InputDecoration textInputDecoration(ValueLV value) {
  return InputDecoration(
      hintText: value.last != null
          ? (value.last.toString().length > 40
              ? "${value.last.toString().substring(0, 40)}..."
              : value.last.toString())
          : "");
}

DateTimeField dateTimeField(
    {bool showDate,
    bool showTime,
    BuildContext context,
    ValueLV value,
    Function(dynamic) onChanged}) {

  if (!showDate && !showTime) throw Exception("Nonsene dateTimeField");
  DateFormat format = DateFormat(
      "${showDate ? "yyyy-MM-dd" : ""}${showTime && showDate ? " " : ""}${showTime ? "HH:mm" : ""}");

  return DateTimeField(
    initialValue: value.current,
    onChanged: onChanged,
    format: format,
    focusNode: value.focus,
    decoration: InputDecoration(
        hintText: value.last != null
            ? format.format(value.last)
            : format.format(DateTime.now())),
    onShowPicker: (context, currentValue) async {
      DateTime date;
      TimeOfDay time;
      if (showDate) {
        date = await showDatePicker(
            context: context,
            firstDate: DateTime(1900),
            initialDate: currentValue ?? DateTime.now(),
            lastDate: DateTime(2100));
      }
      date = date ?? DateTime.now();

      if (showTime) {
        time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(currentValue ?? DateTime.now()),
        );
        time = time ?? TimeOfDay.fromDateTime(currentValue ?? DateTime.now());
        return DateTimeField.combine(date, time);
      } else {
        return date;
      }
    },
  );
}
