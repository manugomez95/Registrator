import 'package:bitacora/bloc/app_data/app_data_state.dart';
import 'package:bitacora/main.dart';
import 'package:bitacora/model/app_data.dart';
import 'package:bitacora/ui/components/empty_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bitacora/bloc/form/bloc.dart';
import 'package:bitacora/model/action.dart' as app;
import 'package:bitacora/model/table.dart' as app;
import 'package:bitacora/ui/components/properties_form.dart';
import 'package:bitacora/ui/components/snack_bars.dart';
import 'package:bitacora/conf/style.dart' as app;

// TODO maybe this should be Stateful y destination view Stateless
class ActionsPage extends StatelessWidget {
  const ActionsPage();

  @override
  Widget build(BuildContext context) {
    // ignore: close_sinks
    final bloc = getIt<AppData>().bloc;
    return BlocProvider(
        create: (BuildContext context) => bloc,
        child: BlocBuilder(
          bloc: bloc,
          builder: (BuildContext context, AppDataState state) {
            print(state);
            if (state is InitialAppDataState ||
                (state.loadingStack.isNotEmpty && getIt<AppData>().getTables().isEmpty)) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (getIt<AppData>().getTables().isEmpty && state.loadingStack.isEmpty) {
              return EmptyView();
            } else
              return ActionsDropdown(); // TODO test case when DB has no tables
          },
        ));
  }
}

class ActionsDropdown extends StatefulWidget implements PreferredSizeWidget {
  @override
  _ActionsDropdownState createState() => _ActionsDropdownState();

  @override
  Size get preferredSize => const Size(double.infinity, kToolbarHeight);
}

class _ActionsDropdownState extends State<ActionsDropdown> {
  List<app.Action> actions = <app.Action>[];
  app.Action selectedAction;

  @override
  void initState() {
    super.initState();
    actions = app.actions;
    selectedAction = actions[0]; // TODO I should access persistent data here
  }

  @override
  Widget build(BuildContext context) {
    print("_ActionsDropdownState build");
    return Column(
      children: <Widget>[
        Theme(
          data: ThemeData(canvasColor: app.Style.darkGrey),
          child: DropdownButtonHideUnderline(
              child: Container(
            color: selectedAction.primaryColor,
            child: DropdownButton<app.Action>(
                value: selectedAction,
                iconSize: 0,
                isExpanded: true,
                onChanged: (app.Action newValue) {
                  setState(() {
                    selectedAction = newValue;
                  });
                },
                items: actions
                    .map<DropdownMenuItem<app.Action>>((app.Action action) {
                  return DropdownMenuItem<app.Action>(
                      value: action,
                      child: Center(
                          child: Text(action.title,
                              style: TextStyle(
                                  color: action.textColor,
                                  fontWeight: FontWeight.bold))));
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
  final _formBloc =
      FormBloc(); // TODO necessary? maybe not for the moment (we don't need to manage state)

  @override
  Widget build(BuildContext context) {
    tables = getIt<AppData>().getTables();
    if (!tables.contains(selectedTable)) selectedTable = tables.first;
    PropertiesForm form = PropertiesForm(selectedTable, widget.action);
    return Expanded(
      child: Scaffold(
        appBar: buildTablesDropdown(),
        body: RefreshIndicator(
          child: Dismissible(
            // TODO only for editlast from
            child: form,
            key: UniqueKey(),
            background: Container(color: Colors.red),
            onDismissed: (direction) {
              // Remove the item from the data source.
              setState(() {
                selectedTable.client.cancelLastInsertion(selectedTable,
                    form.propertiesForm); // TODO Remove last with linearity
              });
              // Then show a snackbar.
              Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text("Deleted"))); // TODO call made function
            },
          ),
          onRefresh: () async {
            form.formKey.currentState.reset();
            getIt<AppData>().getDbs().forEach((db) async {
              // TODO update status?
              await db.updateDatabaseModel();
            });
            setState(() {
              tables = getIt<AppData>().getTables();
            });
            return null;
          },
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            backgroundColor: widget.action.primaryColor,
            tooltip: "${widget.action.title} ${selectedTable.name}",
            child: Icon(
              Icons.check,
              color: widget.action.textColor,
            ),
            onPressed: () {
              if (form.formKey.currentState.validate()) {
                switch (widget.action.type) {
                  case app.ActionType.InsertInto:
                    _formBloc.add(InsertSubmitForm(context, form.propertiesForm,
                        widget.action, selectedTable));
                    break;
                  case app.ActionType.EditLastFrom:
                    _formBloc.add(EditSubmitForm(context, form.propertiesForm,
                        widget.action, selectedTable));
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
    return PreferredSize(
      preferredSize: Size(double.infinity, kToolbarHeight),
      child: Container(
        color: app.Style.lightGrey,
        child: DropdownButtonHideUnderline(
            child: Theme(
          data: ThemeData(canvasColor: app.Style.lightGrey),
          child: DropdownButton<String>(
              value: selectedTable.name,
              iconSize: 0,
              elevation: 0,
              isExpanded: true,
              onChanged: (String newValue) {
                setState(() {
                  selectedTable = tables
                      .where((t) => t.name == newValue)
                      .first; // TODO not very clean and not robust
                });
              },
              items: tables.map<DropdownMenuItem<String>>((app.Table table) {
                return DropdownMenuItem<String>(
                    value: table.name,
                    child: Center(
                        child: Text(table.name,
                            style: TextStyle(color: Colors.black))));
              }).toList()),
        )),
      ),
    );
  }
}
