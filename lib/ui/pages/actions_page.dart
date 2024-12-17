import 'package:bitacora/bloc/app_data/app_data_state.dart';
import 'package:bitacora/conf/style.dart';
import 'package:bitacora/main.dart';
import 'package:bitacora/model/app_data.dart';
import 'package:bitacora/ui/components/confirm_dialog.dart';
import 'package:bitacora/ui/components/empty_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bitacora/bloc/form/bloc.dart';
import 'package:bitacora/model/action.dart' as app;
import 'package:bitacora/model/table.dart' as app;
import 'package:bitacora/ui/components/properties_form.dart';
import 'package:bitacora/ui/components/snack_bars.dart';
import 'package:get_it/get_it.dart';

class ActionsPage extends StatelessWidget {
  const ActionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appData = GetIt.I<AppData>();
    final actions = appData.actions;
    final tables = appData.dbs.expand((db) => db.tables).toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ActionsDropdown(actions: actions, tables: tables),
      ),
      body: const Center(
        child: Text('Select an action and table to begin'),
      ),
    );
  }
}

class ActionsDropdown extends StatefulWidget {
  final List<app.Action> actions;
  final List<app.Table> tables;

  const ActionsDropdown({
    required this.actions,
    required this.tables,
    super.key,
  });

  @override
  State<ActionsDropdown> createState() => _ActionsDropdownState();
}

class _ActionsDropdownState extends State<ActionsDropdown> {
  app.Action? selectedAction;
  app.Table? selectedTable;
  PropertiesForm? form;

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
                  if (newValue != null) {
                    setState(() {
                      selectedAction = newValue;
                      selectedTable = null;
                      form = null;
                    });
                  }
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
                    if (newTable != null) {
                      setState(() {
                        selectedTable = newTable;
                        form = PropertiesForm(
                          formKey: GlobalKey<FormState>(),
                          properties: selectedTable!.properties.toList(),
                          action: selectedAction!,
                        );
                      });
                    }
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
