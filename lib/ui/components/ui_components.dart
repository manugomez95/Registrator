import 'package:flutter/material.dart';
import 'package:bitacora/model/property.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:bitacora/utils/db_parameter.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class CustomDropdownButton<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final void Function(T?)? onChanged;
  final String? hint;

  const CustomDropdownButton({
    Key? key,
    this.value,
    required this.items,
    required this.labelBuilder,
    this.onChanged,
    this.hint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      value: value,
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(labelBuilder(item)),
        );
      }).toList(),
      onChanged: onChanged,
      hint: hint != null ? Text(hint!) : null,
    );
  }
}

class CustomDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const CustomDialog({
    Key? key,
    required this.title,
    required this.content,
    this.onConfirm,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class CustomSnackBar extends SnackBar {
  CustomSnackBar({
    Key? key,
    required String message,
    VoidCallback? onUndo,
  }) : super(
          key: key,
          content: Text(message),
          action: onUndo != null
              ? SnackBarAction(
                  label: 'Undo',
                  onPressed: onUndo,
                )
              : null,
        );
}

class PropertyFormField extends StatelessWidget {
  final Property property;
  final dynamic value;
  final ValueChanged<dynamic>? onChanged;
  final String? Function(String?)? validator;
  final bool readOnly;
  final bool isArray;
  final VoidCallback? onRemove;
  final bool showRemoveButton;

  const PropertyFormField({
    Key? key,
    required this.property,
    this.value,
    this.onChanged,
    this.validator,
    this.readOnly = false,
    this.isArray = false,
    this.onRemove,
    this.showRemoveButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMainInput(context),
        ),
        if (showRemoveButton && onRemove != null) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: onRemove,
            color: Colors.red,
          ),
        ],
      ],
    );
  }

  Widget _buildMainInput(BuildContext context) {
    // Handle foreign key fields with TypeAheadFormField
    if (property.foreignKeyOf != null) {
      return _buildTypeAheadField(context);
    }

    switch (property.type.primitive) {
      case PrimitiveType.timestamp:
      case PrimitiveType.date:
      case PrimitiveType.time:
        return _buildDateTimePicker(context);
      case PrimitiveType.boolean:
        return _buildCheckbox();
      default:
        return _buildTextField();
    }
  }

  Widget _buildTypeAheadField(BuildContext context) {
    return TypeAheadFormField<String>(
      textFieldConfiguration: TextFieldConfiguration(
        decoration: InputDecoration(
          labelText: property.name,
          border: const OutlineInputBorder(),
        ),
        controller: TextEditingController(text: value?.toString() ?? ''),
        enabled: !readOnly,
      ),
      suggestionsCallback: (pattern) async {
        return await property.foreignKeyOf!.client?.getPkDistinctValues(
          property.foreignKeyOf!,
          pattern: pattern,
        ) ?? [];
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          title: Text(suggestion.toString()),
        );
      },
      onSuggestionSelected: (suggestion) {
        if (onChanged != null) {
          onChanged!(suggestion);
        }
      },
      validator: validator ?? _defaultValidator,
    );
  }

  Widget _buildDateTimePicker(BuildContext context) {
    final bool showDate = property.type.primitive != PrimitiveType.time;
    final bool showTime = property.type.primitive != PrimitiveType.date;

    // Use Future.microtask to schedule the initialization after the build
    if (value == null && onChanged != null) {
      Future.microtask(() {
        final now = DateTime.now();
        final defaultValue = DateTime(
          now.year,
          now.month, 
          now.day,
          showTime ? now.hour : 0,
          showTime ? now.minute : 0
        );
        onChanged!(defaultValue);
      });
    }
    
    return InkWell(
      onTap: readOnly ? null : () async {
        DateTime? selectedDate;
        TimeOfDay? selectedTime;
        
        if (showDate) {
          selectedDate = await showDatePicker(
            context: context,
            initialDate: (value as DateTime?) ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
          );
          if (selectedDate == null) return;
        }
        
        if (showTime) {
          selectedTime = await showTimePicker(
            context: context,
            initialTime: value != null ? TimeOfDay.fromDateTime(value as DateTime) : TimeOfDay.now(),
          );
          if (selectedTime == null && showDate == false) return;
        }

        if (onChanged != null) {
          final DateTime now = DateTime.now();
          final DateTime result = DateTime(
            selectedDate?.year ?? now.year,
            selectedDate?.month ?? now.month,
            selectedDate?.day ?? now.day,
            selectedTime?.hour ?? (showTime ? now.hour : 0),
            selectedTime?.minute ?? (showTime ? now.minute : 0),
          );
          onChanged!(result);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: property.name,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          value?.toString() ?? '',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: readOnly ? Theme.of(context).disabledColor : null,
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox() {
    return CheckboxListTile(
      title: Text(property.name),
      value: value as bool? ?? false,
      onChanged: readOnly ? null : (bool? newValue) {
        if (onChanged != null) {
          onChanged!(newValue);
        }
      },
    );
  }

  Widget _buildTextField() {
    final bool isNumeric = [
      PrimitiveType.integer,
      PrimitiveType.smallInt,
      PrimitiveType.bigInt,
      PrimitiveType.real,
      PrimitiveType.byteArray,
    ].contains(property.type.primitive);

    return TextFormField(
      decoration: InputDecoration(
        labelText: property.name,
        border: const OutlineInputBorder(),
      ),
      initialValue: value?.toString() ?? '',
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      maxLength: property.charMaxLength,
      maxLines: property.type.primitive == PrimitiveType.text ? null : 1,
      readOnly: readOnly,
      onChanged: onChanged != null ? (String value) {
        dynamic parsedValue = value;
        if (isNumeric && value.isNotEmpty) {
          try {
            if (property.type.primitive == PrimitiveType.real) {
              parsedValue = double.parse(value);
            } else {
              parsedValue = int.parse(value);
            }
          } catch (_) {
            // Keep as string if parsing fails
          }
        }
        onChanged!(parsedValue);
      } : null,
      validator: validator ?? _defaultValidator,
    );
  }

  String? _defaultValidator(String? value) {
    if (!property.isNullable && (value == null || value.isEmpty)) {
      return '${property.name} is required';
    }
    return null;
  }
}

class TableCard extends StatelessWidget {
  final app.Table table;
  final VoidCallback? onTap;

  const TableCard({
    Key? key,
    required this.table,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(table.name),
        subtitle: Text('${table.properties.length} columns'),
        trailing: Icon(
          table.visible ? Icons.visibility : Icons.visibility_off,
          color: Theme.of(context).colorScheme.secondary,
        ),
        onTap: onTap,
      ),
    );
  }
}

class PropertyListTile extends StatelessWidget {
  final Property property;
  final bool isSelected;
  final VoidCallback? onTap;

  const PropertyListTile({
    Key? key,
    required this.property,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(property.name),
      subtitle: Text(property.type.name),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
} 