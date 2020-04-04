import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:bitacora/main.dart';
import 'package:bitacora/model/app_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bitacora/bloc/database_model/bloc.dart';
import 'package:bitacora/bloc/form/bloc.dart';
import 'package:bitacora/model/action.dart' as app;
import 'package:bitacora/model/table.dart' as app;
import 'package:bitacora/ui/components/properties_form.dart';
import 'package:bitacora/ui/components/snack_bars.dart';
import 'package:http/http.dart';
import 'package:rxdart/rxdart.dart';
import 'package:bitacora/conf/style.dart' as app;

// TODO Stateful o Stateless?
class ActionsPage extends StatefulWidget {
  const ActionsPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ActionsPageState();
}

class ActionsPageState extends State<ActionsPage> {
  final _dbModelBloc = getIt<DatabaseModelBloc>(); // TODO actually it's a AppDataBloc

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (BuildContext context) => _dbModelBloc,
        child: BlocBuilder(
          bloc: _dbModelBloc,
          builder: (BuildContext context, DatabaseModelState state) {
            if (state is DatabaseModelInitial || state is AttemptingDbConnection || getIt<AppData>().dbs.isEmpty) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else
              return ActionsDropdown(); // TODO test case when DB has no tables
          },
        ));
  }

  @override
  void dispose() {
    super.dispose();
    _dbModelBloc.close();
  }
}

class Actions {
  BehaviorSubject _selectedAction = BehaviorSubject.seeded(app.actions[0]);
  Stream get stream$ => _selectedAction.stream;
  app.Action get current => _selectedAction.value;
  select(value) {
    _selectedAction.add(value);
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
    print("_ActionsDropdownState.initState: ${getIt<AppData>().dbs}");
    actions = app.actions;
    selectedAction = actions[0]; // TODO I should access persistent data here
  }

  @override
  Widget build(BuildContext context) {
    print("_ActionsDropdownState.build: ${getIt<AppData>().dbs}");
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
                items: actions.map<DropdownMenuItem<app.Action>>(
                    (app.Action action) {
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
        TablesDropdown(selectedAction, getIt<AppData>().dbs.map((PostgresClient db) => db.tables).expand((i) => i).toList())
      ],
    );
  }
}

class TablesDropdown extends StatefulWidget {
  TablesDropdown(this.action, this.tables);

  final app.Action action;
  final List<app.Table> tables;

  @override
  TablesDropdownState createState() {
    TablesDropdownState state = TablesDropdownState();
    return state;
  }
}

class TablesDropdownState extends State<TablesDropdown> {
  app.Table selectedTable;
  final _formBloc = FormBloc(); // TODO necessary?

  @override
  void initState() {
    super.initState();
    selectedTable = widget.tables.first; // TODO I should access persistent data here
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.tables.contains(selectedTable)) selectedTable = widget.tables.first;
    PropertiesForm form = PropertiesForm(selectedTable, widget.action.title);
    return Expanded(
      child: Scaffold(
        appBar: buildTablesDropdown(),
        body: form,
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            backgroundColor: widget.action.primaryColor,
            tooltip: "${widget.action} ${selectedTable.name}",
            child: Icon(
              Icons.check,
              color: widget.action.textColor,
            ),
            onPressed: () {
              if (form.formKey.currentState.validate()) {
                _formBloc.add(SubmitFormEvent(context, form.propertiesForm,
                    widget.action, selectedTable));
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
                  selectedTable = widget.tables
                      .where((t) => t.name == newValue)
                      .first; // TODO not very clean and not robust
                });
              },
              items: widget.tables.map<DropdownMenuItem<String>>((app.Table table) {
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
