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

class ActionsPage extends StatelessWidget {
  const ActionsPage();

  @override
  Widget build(BuildContext context) {
    // ignore: close_sinks
    final bloc = getIt<AppData>().bloc;
    ThemeData theme = Theme.of(context);
    return BlocProvider(
        create: (BuildContext context) => bloc,
        child: BlocBuilder(
          bloc: bloc,
          builder: (BuildContext context, AppDataState state) {
            if (getIt<AppData>().getTables().isEmpty) {
              if (state.loadingStack.isNotEmpty || state is Loading) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              else {
                return EmptyView();
              }
            } else
              return ActionsDropdown(actions: <app.Action>[
                app.Action(app.ActionType.InsertInto, theme.colorScheme.insertBgColor ?? theme.colorScheme.actionsDropdownBg, theme.colorScheme.insertTextColor ?? theme.colorScheme.actionsDropdownTextColor, theme.brightness),
                app.Action(app.ActionType.EditLastFrom, theme.colorScheme.editBgColor ?? theme.colorScheme.actionsDropdownBg, theme.colorScheme.editTextColor ?? theme.colorScheme.actionsDropdownTextColor, theme.brightness),
                app.Action(app.ActionType.CreateWidgetFrom, theme.colorScheme.createWidgetBgColor ?? theme.colorScheme.actionsDropdownBg, theme.colorScheme.createWidgetTextColor ?? theme.colorScheme.actionsDropdownTextColor, theme.brightness),
              ]);
          },
        ));
  }
}

class ActionsDropdown extends StatefulWidget implements PreferredSizeWidget {
  final List<app.Action> actions;

  const ActionsDropdown({Key key, this.actions}) : super(key: key);

  @override
  _ActionsDropdownState createState() => _ActionsDropdownState();

  @override
  Size get preferredSize => const Size(double.infinity, kToolbarHeight);
}

class _ActionsDropdownState extends State<ActionsDropdown> {
  app.Action selectedAction;

  setLastAction(app.Action action) async {
    final prefs = await getIt<AppData>().sharedPrefs;
    return prefs.setInt("lastAction", action.type.index);
  }

  @override
  Widget build(BuildContext context) {
    /// to update selected action's colors. I haven't come up with a more efficient way...
    selectedAction = widget.actions.firstWhere((a) => a == selectedAction, orElse: () => widget.actions.first);
    ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Theme(
          data: ThemeData(canvasColor: theme.colorScheme.actionsDropdownBg),
          child: DropdownButtonHideUnderline(
              child: Container(
            color: selectedAction.bgColor,
            child: DropdownButton<app.Action>(
                value: selectedAction,
                iconSize: 0,
                isExpanded: true,
                onChanged: (app.Action newValue) {
                  setState(() {
                    selectedAction = newValue;
                    setLastAction(selectedAction);
                  });
                },
                items: widget.actions
                    .map<DropdownMenuItem<app.Action>>((app.Action action) {
                  return DropdownMenuItem<app.Action>(
                      value: action,
                      child: Center(
                          child: Text(action.title,
                              style: TextStyle(
                                  color: action.textColor,
                                  fontWeight: FontWeight.w600))));
                }).toList()),
          )),
        ),
        TablesDropdown(
          selectedAction,
        )
      ],
    );
  }
}

class TablesDropdown extends StatefulWidget {
  TablesDropdown(this.action);
  final app.Action action;

  @override
  TablesDropdownState createState() {
    TablesDropdownState state = TablesDropdownState();
    return state;
  }
}

class TablesDropdownState extends State<TablesDropdown> {
  List<app.Table> tables;
  app.Table selectedTable;

  /// necessary? YES, re-builds the form when an event is released (like editLastFrom, removeLastFrom...)
  final _formBloc = FormBloc();

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    /// this needs to be here to update the tables when refreshing
    tables = getIt<AppData>().getTables();
    if (!tables.contains(selectedTable)) selectedTable = tables.first;
    return BlocProvider(
        create: (BuildContext context) => _formBloc,
        child: BlocBuilder(
            bloc: _formBloc,
            builder: (BuildContext context, PropertiesFormState state) {
              PropertiesForm form =
                  PropertiesForm(selectedTable, widget.action);
              return Expanded(
                child: Scaffold(
                  appBar: buildTablesDropdown(),
                  body: RefreshIndicator(
                    child: widget.action.type == app.ActionType.EditLastFrom
                        ? Dismissible(
                            child: form,
                            key: UniqueKey(),
                            background: Container(color: Colors.red),
                            onDismissed: (direction) {
                              // Remove the item from the data source.
                              setState(() {
                                _formBloc.add(
                                    DeleteLastEntry(selectedTable, context));
                              });
                            },
                            confirmDismiss: (direction) async {
                              return asyncConfirmDialog(context,
                                  title: "Remove last entry?");
                            },
                          )
                        : form,
                    onRefresh: () async {
                      await selectedTable.client.getLastRow(selectedTable);
                      setState(() {
                        form.formKey.currentState.reset();
                      });
                      return null;
                    },
                  ),
                  floatingActionButton: Builder(
                    builder: (context) => FloatingActionButton(
                      backgroundColor: widget.action.floatButColor,
                      tooltip: "${widget.action.title} ${selectedTable.name}",
                      child: Icon(
                        Icons.check,
                        color: theme.colorScheme.negativeDefaultTxtColor,
                      ),
                      onPressed: () {
                        if (form.formKey.currentState.validate()) {
                          switch (widget.action.type) {
                            case app.ActionType.InsertInto:
                              _formBloc.add(InsertSubmitForm(
                                  context,
                                  form.propertiesForm,
                                  widget.action,
                                  selectedTable));
                              break;
                            case app.ActionType.EditLastFrom:
                              _formBloc.add(EditSubmitForm(
                                  context,
                                  form.propertiesForm,
                                  widget.action,
                                  selectedTable));
                              break;
                            default:
                              showErrorSnackBar(context, "Not implemented yet");
                          }
                        } else
                          showErrorSnackBar(context, "Check for wrong input");
                      },
                    ),
                  ),
                ),
              );
            }));
  }

  Widget buildTablesDropdown() {
    ThemeData theme = Theme.of(context);
    return PreferredSize(
      preferredSize: Size(double.infinity, kToolbarHeight),
      child: Container(
        color: theme.colorScheme.tablesDropdownBg,
        child: DropdownButtonHideUnderline(
            child: Theme(
          data: ThemeData(canvasColor: theme.colorScheme.tablesDropdownBg),
          child: DropdownButton<app.Table>(
              value: selectedTable,
              iconSize: 0,
              elevation: 0,
              isExpanded: true,
              onChanged: (app.Table newTable) {
                setState(() {
                  selectedTable = newTable;
                });
              },
              items: tables.map<DropdownMenuItem<app.Table>>((app.Table table) {
                return DropdownMenuItem<app.Table>(
                    value: table,
                    child: Center(
                        child: Text(table.name,
                            style: TextStyle(
                                color: theme
                                    .colorScheme.tablesDropdownTextColor))));
              }).toList()),
        )),
      ),
    );
  }
}
