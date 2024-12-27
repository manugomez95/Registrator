import 'package:bitacora/model/app_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bitacora/bloc/form/bloc.dart';
import 'package:bitacora/bloc/form/form_bloc.dart';
import 'package:bitacora/bloc/form/form_event.dart';
import 'package:bitacora/bloc/form/form_state.dart';
import 'package:bitacora/model/action.dart' as app;
import 'package:bitacora/model/table.dart' as app;
import 'package:bitacora/model/property.dart';
import 'package:bitacora/ui/components/properties_form.dart';
import 'package:provider/provider.dart';

class ActionsPage extends StatefulWidget {
  const ActionsPage({Key? key}) : super(key: key);

  @override
  State<ActionsPage> createState() => _ActionsPageState();
}

class _ActionsPageState extends State<ActionsPage> {
  PropertiesForm? form;
  late FormBloc formBloc;

  @override
  void initState() {
    super.initState();
    formBloc = FormBloc();
  }

  @override
  void dispose() {
    formBloc.close();
    super.dispose();
  }

  void updateForm(PropertiesForm? newForm) {
    setState(() {
      form = newForm;
    });
  }

  Future<void> _handleRefresh() async {
    setState(() {
      form?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: formBloc,
      child: BlocListener<FormBloc, PropertiesFormState>(
        listener: (context, state) {
          if (state is InitialFormState) {
            // Form will handle its own reset
            form?.reset();
          }
        },
        child: Consumer<AppData>(
          builder: (context, appData, child) {
            print("\n=== ActionsPage Build ===");
            appData.debugDatabaseState();
            print("Tables available to Actions page: ${appData.tables.length}");
            print("======================\n");

            return Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: ActionsDropdown(
                  actions: appData.actions,
                  tables: appData.tables,
                  onFormUpdated: updateForm,
                ),
              ),
              body: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: form ??
                    const Center(
                      child: Text('Select an action and table to begin'),
                    ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ActionsDropdown extends StatefulWidget {
  final List<app.Action> actions;
  final List<app.Table> tables;
  final Function(PropertiesForm?) onFormUpdated;

  const ActionsDropdown({
    required this.actions,
    required this.tables,
    required this.onFormUpdated,
    super.key,
  });

  @override
  State<ActionsDropdown> createState() => _ActionsDropdownState();
}

class _ActionsDropdownState extends State<ActionsDropdown> {
  app.Action? selectedAction;
  app.Table? selectedTable;

  Map<Property, dynamic> _convertFormData(
      Map<String, dynamic> formData, List<Property> properties) {
    final result = <Property, dynamic>{};
    for (final property in properties) {
      if (formData.containsKey(property.name)) {
        result[property] = formData[property.name];
      }
    }
    return result;
  }

  void _updateForm() {
    if (selectedAction != null && selectedTable != null) {
      final formBloc = context.read<FormBloc>();
      final properties = selectedTable!.properties.toList();
      widget.onFormUpdated(PropertiesForm(
        formKey: GlobalKey<FormState>(),
        properties: properties,
        action: selectedAction!,
        onSubmit: (values) {
          final convertedValues = _convertFormData(values, properties);
          formBloc.add(SubmitFormEvent(
            context,
            selectedTable!,
            selectedAction!,
            convertedValues,
          ));
        },
      ));
    } else {
      widget.onFormUpdated(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AppBar(
        title: Row(
          children: [
            Expanded(
              child: DropdownButton<app.Action>(
                value: selectedAction,
                items: widget.actions.map((app.Action action) {
                  return DropdownMenuItem<app.Action>(
                    value: action,
                    child: Text(action.name),
                  );
                }).toList(),
                onChanged: (app.Action? newValue) {
                  setState(() {
                    selectedAction = newValue;
                    selectedTable = null;
                  });
                  _updateForm();
                },
                hint: const Text('Select an action'),
              ),
            ),
            if (selectedAction != null) ...[
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<app.Table>(
                  value: selectedTable,
                  items: widget.tables.map((app.Table table) {
                    return DropdownMenuItem<app.Table>(
                      value: table,
                      child: Text(table.name),
                    );
                  }).toList(),
                  onChanged: (app.Table? newTable) {
                    setState(() {
                      selectedTable = newTable;
                    });
                    _updateForm();
                  },
                  hint: const Text('Select a table'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
