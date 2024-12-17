import 'package:bitacora/bloc/database/database_event.dart';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'form_field_view.dart';
import 'package:bitacora/conf/style.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum DbFormType { 
  connect, 
  edit,
  create 
}

/// Needs to be Stateful because it contains a CheckBox
class DbForm extends StatefulWidget {
  final DbFormType type;
  final DbClient? db;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  DbForm(this.type, {Key? key, this.db}) : super(key: key);

  @override
  State<DbForm> createState() => DbFormState();
}

class DbFormState extends State<DbForm> {
  late String selectedDbType;
  final Map<String, dynamic> formData = {};
  final TextEditingController aliasController = TextEditingController();
  final TextEditingController hostController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController databaseController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool useSSL = false;
  bool isEditMode = false;

  @override
  void initState() {
    super.initState();
    isEditMode = widget.db != null;
    selectedDbType = widget.db?.params.brand ?? 'postgres';
    if (widget.db != null) {
      aliasController.text = widget.db!.params.alias;
      hostController.text = widget.db!.params.host;
      portController.text = widget.db!.params.port.toString();
      databaseController.text = widget.db!.params.dbName;
      usernameController.text = widget.db!.params.username;
      passwordController.text = '';
      useSSL = widget.db!.params.useSSL;
    }
  }

  @override
  void dispose() {
    aliasController.dispose();
    hostController.dispose();
    portController.dispose();
    databaseController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  List<Widget> _buildFormFields() {
    final fields = <Widget>[
      TextFormField(
        controller: aliasController,
        decoration: const InputDecoration(
          labelText: 'Connection Name',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a connection name';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
    ];

    if (selectedDbType == 'sqlite') {
      fields.addAll([
        TextFormField(
          controller: databaseController,
          decoration: const InputDecoration(
            labelText: 'Database File Path',
            border: OutlineInputBorder(),
            hintText: 'Path to your SQLite database file',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the database file path';
            }
            return null;
          },
        ),
      ]);
    } else {
      fields.addAll([
        TextFormField(
          controller: hostController,
          decoration: const InputDecoration(
            labelText: 'Host',
            border: OutlineInputBorder(),
            hintText: 'localhost or host address',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the host';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: portController,
          decoration: const InputDecoration(
            labelText: 'Port',
            border: OutlineInputBorder(),
            hintText: '5432',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the port';
            }
            final port = int.tryParse(value);
            if (port == null) {
              return 'Please enter a valid port number';
            }
            if (port <= 0 || port > 65535) {
              return 'Port must be between 1 and 65535';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: databaseController,
          decoration: const InputDecoration(
            labelText: 'Database Name',
            border: OutlineInputBorder(),
            hintText: 'Name of your database',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the database name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: usernameController,
          decoration: const InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
            hintText: 'Database user',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the username';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
            hintText: isEditMode ? 'Leave empty to keep current password' : 'Database password',
          ),
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty && !isEditMode) {
              return 'Please enter the password';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('Use SSL'),
          subtitle: const Text('Enable secure connection'),
          value: useSSL,
          onChanged: (bool? value) {
            setState(() {
              useSSL = value ?? false;
            });
          },
        ),
      ]);
    }

    return fields;
  }

  void _saveForm() {
    try {
      if (widget.formKey.currentState?.validate() ?? false) {
        formData['brand'] = selectedDbType;
        formData['alias'] = aliasController.text.trim();
        formData['host'] = selectedDbType == 'sqlite' ? '' : hostController.text.trim();
        formData['port'] = selectedDbType == 'sqlite' ? 0 : int.parse(portController.text.trim());
        formData['db_name'] = databaseController.text.trim();
        formData['username'] = selectedDbType == 'sqlite' ? '' : usernameController.text.trim();
        formData['isEditing'] = isEditMode;
        
        final password = passwordController.text.trim();
        if (isEditMode && password.isEmpty && widget.db != null) {
          formData['password'] = widget.db!.params.password;
        } else {
          formData['password'] = password;
        }
        
        formData['useSSL'] = selectedDbType == 'sqlite' ? false : useSSL;
        
        Navigator.of(context).pop(formData);
      } else {
        Fluttertoast.showToast(
          msg: "Please fix the errors in the form",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error saving form: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type == DbFormType.create ? 'New Connection' : 'Edit Connection'),
        actions: [
          TextButton(
            child: Text(
              'Save',
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
            onPressed: _saveForm,
          ),
        ],
      ),
      body: Form(
        key: widget.formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            DropdownButtonFormField<String>(
              value: selectedDbType,
              items: ['postgres', 'sqlite', 'bigquery'].map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedDbType = newValue;
                    // Clear form fields when changing database type
                    if (widget.db == null) {
                      hostController.clear();
                      portController.clear();
                      databaseController.clear();
                      usernameController.clear();
                      passwordController.clear();
                      useSSL = false;
                    }
                  });
                }
              },
              decoration: const InputDecoration(
                labelText: 'Database Type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ..._buildFormFields(),
          ],
        ),
      ),
    );
  }
}
