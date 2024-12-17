import 'package:flutter/material.dart';
import 'package:bitacora/model/action.dart' as app;
import 'package:bitacora/model/property.dart';
import 'package:bitacora/utils/db_parameter.dart';

class PropertiesForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final List<Property> properties;
  final app.Action action;
  final Function(Map<String, dynamic>)? onSubmit;

  const PropertiesForm({
    Key? key,
    required this.formKey,
    required this.properties,
    required this.action,
    this.onSubmit,
  }) : super(key: key);

  @override
  State<PropertiesForm> createState() => _PropertiesFormState();
}

class _PropertiesFormState extends State<PropertiesForm> {
  final Map<String, dynamic> _formData = {};

  dynamic _parseValue(String value, DataType type) {
    if (value.isEmpty) return null;
    switch (type.primitive) {
      case PrimitiveType.integer:
        return int.tryParse(value);
      case PrimitiveType.real:
        return double.tryParse(value);
      case PrimitiveType.boolean:
        return value.toLowerCase() == 'true';
      case PrimitiveType.timestamp:
      case PrimitiveType.date:
        return DateTime.tryParse(value);
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: widget.properties.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final property = widget.properties[index];
                return _buildFormField(property);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                if (widget.formKey.currentState?.validate() ?? false) {
                  widget.onSubmit?.call(_formData);
                }
              },
              child: Text('Submit ${widget.action.name}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(Property property) {
    switch (property.type.primitive) {
      case PrimitiveType.boolean:
        return CheckboxListTile(
          title: Text(property.name),
          value: _formData[property.name] as bool? ?? false,
          onChanged: (value) {
            setState(() {
              _formData[property.name] = value;
            });
          },
        );
      case PrimitiveType.timestamp:
      case PrimitiveType.date:
        return InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _formData[property.name] as DateTime? ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              setState(() {
                _formData[property.name] = date;
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: property.name,
              border: const OutlineInputBorder(),
            ),
            child: Text(
              _formData[property.name]?.toString() ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );
      default:
        return TextFormField(
          decoration: InputDecoration(
            labelText: property.name,
            border: const OutlineInputBorder(),
          ),
          initialValue: _formData[property.name]?.toString() ?? '',
          onChanged: (value) {
            setState(() {
              _formData[property.name] = _parseValue(value, property.type);
            });
          },
          validator: (value) {
            if (!property.isNullable && (value == null || value.isEmpty)) {
              return '${property.name} is required';
            }
            return null;
          },
        );
    }
  }

  Map<String, dynamic> get formData => _formData;
}