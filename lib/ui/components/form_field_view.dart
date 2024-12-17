import 'package:flutter/material.dart';

class FormFieldView extends StatefulWidget {
  final String label;
  final String? Function(String?)? validator;
  final TextEditingController controller;
  final bool obscureText;

  const FormFieldView({
    Key? key,
    required this.label,
    this.validator,
    required this.controller,
    this.obscureText = false,
  }) : super(key: key);

  @override
  State<FormFieldView> createState() => _FormFieldViewState();
}

class _FormFieldViewState extends State<FormFieldView> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
      obscureText: widget.obscureText,
      validator: widget.validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter ${widget.label.toLowerCase()}';
        }
        return null;
      },
    );
  }
}
