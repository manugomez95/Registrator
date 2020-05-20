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
    final bloc = getIt<AppData>()
        .bloc; // TODO maybe in the future only listen to all the databases blocs?
    ThemeData theme = Theme.of(context);
    return BlocProvider(
        create: (BuildContext context) => bloc,
        child: BlocBuilder(
          bloc: bloc,
          builder: (BuildContext context, AppDataState state) {
            final Iterable<app.Table> tables = getIt<AppData>().getTables();
            if (tables.isEmpty) {
              if (state.loadingStack.isNotEmpty || state is Loading) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else {
                return EmptyView();
              }
            } else {
              return ActionsDropdown(<app.Action>[
                app.Action(
                    app.ActionType.InsertInto,
                    theme.colorScheme.insertBgColor ??
                        theme.colorScheme.actionsDropdownBg,
                    theme.colorScheme.insertTextColor ??
                        theme.colorScheme.actionsDropdownTextColor,
                    theme.brightness),
                app.Action(
                    app.ActionType.EditLastFrom,
                    theme.colorScheme.editBgColor ??
                        theme.colorScheme.actionsDropdownBg,
                    theme.colorScheme.editTextColor ??
                        theme.colorScheme.actionsDropdownTextColor,
                    theme.brightness),
                //app.Action(app.ActionType.CreateWidgetFrom, theme.colorScheme.createWidgetBgColor ?? theme.colorScheme.actionsDropdownBg, theme.colorScheme.createWidgetTextColor ?? theme.colorScheme.actionsDropdownTextColor, theme.brightness),
              ], tables);
            }
          },
        ));
  }
}

class ActionsDropdown extends StatefulWidget implements PreferredSizeWidget {
  final List<app.Action> actions;
  final Iterable<app.Table> tables;

  const ActionsDropdown(this.actions, this.tables, {Key key}) : super(key: key);

  @override
  _ActionsDropdownState createState() => _ActionsDropdownState();

  @override
  Size get preferredSize => const Size(double.infinity, kToolbarHeight);
}

class _ActionsDropdownState extends State<ActionsDropdown> {
  app.Action selectedAction;

  @override
  Widget build(BuildContext context) {
    /// to update selected action's colors. I haven't come up with a more efficient way...
    selectedAction = widget.actions.firstWhere((a) => a == selectedAction,
        orElse: () => widget.actions.first);
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
                    getIt<AppData>().updateForm = true;
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
        TablesDropdown(selectedAction, widget.tables)
      ],
    );
  }
}

class TablesDropdown extends StatefulWidget {
  final app.Action selectedAction;
  final Iterable<app.Table> tables;

  TablesDropdown(this.selectedAction, this.tables);

  @override
  TablesDropdownState createState() => TablesDropdownState();
}

class TablesDropdownState extends State<TablesDropdown> {
  app.Table selectedTable;

  /// necessary? YES, re-builds the form when an event is released (like editLastFrom, removeLastFrom...)
  final _formBloc = FormBloc();

  PropertiesForm form;

  @override
  void initState() {
    super.initState();
    form = PropertiesForm(
        selectedTable ?? widget.tables.first, widget.selectedAction);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    if (!widget.tables.contains(selectedTable))
      selectedTable = widget.tables.first;

    return Expanded(
      child: Scaffold(
        appBar: buildTablesDropdown(),
        body: BlocProvider(
            create: (BuildContext context) => _formBloc,
            child: BlocBuilder(
                bloc: _formBloc,
                builder: (BuildContext context, PropertiesFormState state) {
                  if (state.rebuildForm || getIt<AppData>().updateForm) // TODO if doesnt work use _formBloc.rebuildForm
                    form = PropertiesForm(selectedTable, widget.selectedAction);
                  getIt<AppData>().updateForm = false;
                  // TODO depending on state form is rebuilt or not
                  return Column(
                    children: <Widget>[
                      Expanded(
                        child: RefreshIndicator(
                          child: widget.selectedAction.type ==
                              app.ActionType.EditLastFrom
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

                          /// Refreshing only updates the last row of the selected table and resets form [Lightweight]
                          /// The user should understand that if he wants to update the db model he should refresh the data tab
                          onRefresh: () async {
                            await selectedTable.client.getLastRow(selectedTable);
                            setState(() {
                              getIt<AppData>().updateForm = true;
                            });
                          },
                        ),
                      ),
                      state.loadingStack.isNotEmpty ? LinearProgressIndicator(value: null,) : SizedBox(height: 0,),
                    ],
                  );
                })
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            heroTag: "ActionsPageFB",
            backgroundColor: widget.selectedAction.floatButColor,
            tooltip:
            "${widget.selectedAction.title} ${selectedTable.name}",
            child: Icon(
              Icons.check,
              color: theme.colorScheme.negativeDefaultTxtColor,
            ),
            onPressed: () {
              if (form.formKey.currentState.validate()) {
                switch (widget.selectedAction.type) {
                  case app.ActionType.InsertInto:
                    _formBloc.add(InsertSubmitForm(
                        context,
                        form.propertiesForm,
                        widget.selectedAction,
                        selectedTable));
                    break;
                  case app.ActionType.EditLastFrom:
                    _formBloc.add(EditSubmitForm(
                        context,
                        form.propertiesForm,
                        widget.selectedAction,
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
                  getIt<AppData>().updateForm = true;
                });
              },
              items: widget.tables
                  .map<DropdownMenuItem<app.Table>>((app.Table table) {
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
