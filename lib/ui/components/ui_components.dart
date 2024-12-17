import 'package:flutter/material.dart';
import 'package:bitacora/model/property.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:bitacora/utils/db_parameter.dart';

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

  const PropertyFormField({
    Key? key,
    required this.property,
    this.value,
    this.onChanged,
    this.validator,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (property.type.primitive) {
      case PrimitiveType.timestamp:
      case PrimitiveType.date:
        return _buildDateTimePicker(context);
      case PrimitiveType.boolean:
        return _buildCheckbox();
      default:
        return _buildTextField();
    }
  }

  Widget _buildDateTimePicker(BuildContext context) {
    return InkWell(
      onTap: readOnly
          ? null
          : () async {
              final date = await showDatePicker(
                context: context,
                initialDate: value as DateTime? ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (date != null && onChanged != null) {
                onChanged!(date);
              }
            },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: property.name,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          value?.toString() ?? '',
          style: Theme.of(context).textTheme.bodyMedium,
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
    return TextFormField(
      decoration: InputDecoration(
        labelText: property.name,
        border: const OutlineInputBorder(),
      ),
      initialValue: value?.toString() ?? '',
      onChanged: onChanged != null ? (String value) => onChanged!(value) : null,
      validator: validator,
      readOnly: readOnly,
    );
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