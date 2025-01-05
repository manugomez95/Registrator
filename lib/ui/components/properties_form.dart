import 'package:flutter/material.dart';
import 'package:bitacora/model/action.dart' as app;
import 'package:bitacora/model/property.dart';
import 'package:bitacora/ui/components/ui_components.dart';

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

  void reset() {
    formKey.currentState?.reset();
    final state = (formKey.currentState?.context.findAncestorStateOfType<_PropertiesFormState>());
    state?.resetData();
  }

  @override
  State<PropertiesForm> createState() => _PropertiesFormState();
}

class _PropertiesFormState extends State<PropertiesForm> {
  final Map<String, List<dynamic>> _formData = {};

  @override
  void initState() {
    super.initState();
    // Initialize form data with last values if in edit mode
    if (widget.action.type == app.ActionType.editLastFrom) {
      for (final property in widget.properties) {
        if (property.type.isArray && property.lastValue != null) {
          _formData[property.name] = List<dynamic>.from(property.lastValue as List);
        } else {
          _formData[property.name] = [property.lastValue];
        }
      }
    }
  }

  void resetData() {
    setState(() {
      _formData.clear();
    });
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
                return _buildPropertyField(property);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                if (widget.formKey.currentState?.validate() ?? false) {
                  final Map<String, dynamic> result = {};
                  _formData.forEach((key, value) {
                    result[key] = value.length == 1 ? value.first : value;
                  });
                  widget.onSubmit?.call(result);
                }
              },
              child: Text('Submit ${widget.action.name}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyField(Property property) {
    if (!_formData.containsKey(property.name)) {
      _formData[property.name] = [null];
    }

    if (property.type.isArray) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._formData[property.name]!.asMap().entries.map((entry) {
            final int index = entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: PropertyFormField(
                property: property,
                value: entry.value,
                isArray: true,
                showRemoveButton: _formData[property.name]!.length > 1,
                onRemove: () {
                  setState(() {
                    _formData[property.name]!.removeAt(index);
                  });
                },
                onChanged: (value) {
                  setState(() {
                    _formData[property.name]![index] = value;
                  });
                },
              ),
            );
          }).toList(),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _formData[property.name]!.add(null);
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
          ),
        ],
      );
    } else {
      return PropertyFormField(
        property: property,
        value: _formData[property.name]?.first,
        onChanged: (value) {
          setState(() {
            _formData[property.name] = [value];
          });
        },
      );
    }
  }
}