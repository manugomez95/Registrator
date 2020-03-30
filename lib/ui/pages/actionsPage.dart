import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bitacora/bloc/database_model/bloc.dart';
import 'package:bitacora/bloc/form/bloc.dart';
import 'package:bitacora/model/action.dart' as app;
import 'package:bitacora/model/databaseModel.dart';
import 'package:bitacora/model/table.dart' as app;
import 'package:bitacora/ui/components/properties_form.dart';
import 'package:bitacora/ui/components/snack_bars.dart';
import 'package:rxdart/rxdart.dart';
import 'package:bitacora/conf/colors.dart' as app;

class ActionsPage extends StatefulWidget {
  const ActionsPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ActionsPageState();
}

class ActionsPageState extends State<ActionsPage> {
  //final _actions = Actions();
  final _dbModelBloc =
      DatabaseModelBloc(); // TODO actually it's a Postgres DBModel

  @override
  void initState() {
    super.initState();
    _dbModelBloc.add(GetDatabaseModel("my_data")); // TODO this will change
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (BuildContext context) => _dbModelBloc,
        child: BlocBuilder(
          bloc: _dbModelBloc,
          builder: (BuildContext context, DatabaseModelState state) {
            if (state is DatabaseModelInitial) {
              return Text("No data");
            } else if (state is DatabaseModelLoading) {
              return buildLoading();
            } else if (state is DatabaseModelLoaded) {
              return buildActionsPage(state.dbModel);
            } else
              throw Exception;
          },
        ));
  }

  Widget buildLoading() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  // TODO review
  Widget buildActionsPage(DatabaseModel dbModel) {
    return Scaffold(
      body: ActionsDropdown(dbModel),
    );
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
  ActionsDropdown(this.dbModel);

  final DatabaseModel dbModel;
  //final Actions actions;

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
    return Column(
      children: <Widget>[
        Theme(
          data: ThemeData(canvasColor: app.Colors.darkGrey),
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
        TablesDropdown(selectedAction, widget.dbModel)
      ],
    );
  }
}

class TablesDropdown extends StatefulWidget {
  TablesDropdown(this.action, this.dbModel);

  final app.Action action; // TODO will be a class
  final DatabaseModel dbModel;

  @override
  _TablesDropdownState createState() => _TablesDropdownState();
}

class _TablesDropdownState extends State<TablesDropdown> {
  List<app.Table> tables = <app.Table>[];
  app.Table selectedTable;
  PropertiesForm form;
  final _formBloc = FormBloc();

  @override
  void initState() {
    super.initState();
    tables = widget.dbModel.tables;
    selectedTable = tables[0]; // TODO I should access persistent data here
    buildPropertiesForm(selectedTable, widget.action.title);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Scaffold(
        appBar: buildTablesDropdown(),
        body: buildPropertiesForm(selectedTable, widget.action.title),
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
                    widget.action.type, selectedTable));
              } else
                showErrorSnackBar(context, "Check for wrong input");
            },
          ),
        ),
      ),
    );
  }

  PropertiesForm buildPropertiesForm(selectedTable, String action) {
    form = PropertiesForm(selectedTable, action);
    return form;
  }

  Widget buildTablesDropdown() {
    return PreferredSize(
      preferredSize: Size(double.infinity, kToolbarHeight),
      child: Container(
        color: app.Colors.lightGrey,
        child: DropdownButtonHideUnderline(
            child: Theme(
          data: ThemeData(canvasColor: app.Colors.lightGrey),
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
