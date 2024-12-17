import 'package:bitacora/model/property.dart';
import 'package:bitacora/ui/components/property_view.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';

class TypeAheadField extends StatelessWidget {
  final BuildContext context;
  final Property property;
  final ValueLV value;
  final Function(dynamic) onSuggestionSelected;
  final Function(dynamic) onChanged;
  final String? Function(String?)? validator;

  const TypeAheadField({
    Key? key,
    required this.context,
    required this.property,
    required this.value,
    required this.onSuggestionSelected,
    required this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TypeAheadFormField(
      textFieldConfiguration: TextFieldConfiguration(
        controller: TextEditingController(text: value.last?.toString() ?? ''),
        decoration: InputDecoration(
          labelText: property.name,
          border: const OutlineInputBorder(),
        ),
      ),
      suggestionsCallback: (pattern) async {
        if (property.foreignKeyOf == null) return [];
        return property.foreignKeyOf!.client?.getPkDistinctValues(
              property.foreignKeyOf!,
              pattern: pattern,
            ) ??
            [];
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          title: Text(suggestion.toString()),
        );
      },
      onSuggestionSelected: onSuggestionSelected,
      validator: validator,
    );
  }
}

class DateTimeField extends StatelessWidget {
  final bool showDate;
  final bool showTime;
  final BuildContext context;
  final ValueLV value;
  final Function(dynamic) onChanged;

  const DateTimeField({
    Key? key,
    required this.showDate,
    required this.showTime,
    required this.context,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        DateTime? selectedDate = value.last as DateTime?;
        TimeOfDay? selectedTime;

        if (showDate) {
          final date = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
          );
          if (date != null) {
            selectedDate = date;
          }
        }

        if (showTime && context.mounted) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(selectedDate ?? DateTime.now()),
          );
          if (time != null) {
            selectedTime = time;
          }
        }

        if (selectedDate != null) {
          if (selectedTime != null) {
            selectedDate = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              selectedTime.hour,
              selectedTime.minute,
            );
          }
          onChanged(selectedDate);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
        child: Text(
          value.last?.toString() ?? '',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
