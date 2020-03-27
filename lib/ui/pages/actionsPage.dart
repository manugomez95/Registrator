import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:registrator/bloc/database_model/bloc.dart';
import 'package:registrator/bloc/form/bloc.dart';
import 'package:registrator/model/action.dart' as myAction;
import 'package:registrator/model/databaseModel.dart';
import 'package:registrator/model/table.dart' as my;
import 'package:registrator/ui/components/properties_form.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActionsPage extends StatefulWidget {
  const ActionsPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ActionsPageState();
}

class ActionsPageState extends State<ActionsPage> {
  final _actions = Actions();
  final _dbModelBloc = DatabaseModelBloc(); // TODO actually it's a Postgres DBModel

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
      body: ActionsDropdown(_actions, dbModel),
    );
  }
}

class Actions {
  static const list = <myAction.Action>[
    myAction.Action('INSERT INTO', Colors.blue, Colors.white),
    myAction.Action('EDIT LAST FROM', Colors.orangeAccent, Colors.white),
    myAction.Action('CREATE WIDGET FROM', Colors.green, Colors.white),
  ];
  BehaviorSubject _selectedAction = BehaviorSubject.seeded(list[0]);
  Stream get stream$ => _selectedAction.stream;
  myAction.Action get current => _selectedAction.value;
  select(value) {
    _selectedAction.add(value);
  }
}

class ActionsDropdown extends StatefulWidget implements PreferredSizeWidget {
  ActionsDropdown(this.actions, this.dbModel);

  final DatabaseModel dbModel;
  final Actions actions;

  @override
  _ActionsDropdownState createState() => _ActionsDropdownState();

  @override
  Size get preferredSize => const Size(double.infinity, kToolbarHeight);
}

class _ActionsDropdownState extends State<ActionsDropdown> {
  @override
  // TODO change with actions class
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Theme(
          data: ThemeData(canvasColor: Colors.grey[700]),
          child: DropdownButtonHideUnderline(
              child: Container(
                color: widget.actions.current.primaryColor,
          child: DropdownButton<myAction.Action>(
              value: widget.actions.current,
              iconSize: 0,
              isExpanded: true,
              onChanged: (myAction.Action newValue) {
                setState(() {
                  widget.actions.select(newValue);
                });
              },
              items: [
                DropdownMenuItem<myAction.Action>(
                    value: Actions.list[0],
                    child: Center(
                        child: Text(Actions.list[0].title,
                            style: TextStyle(color: Actions.list[0].textColor, fontWeight: FontWeight.bold)))),
                DropdownMenuItem<myAction.Action>(
                    value: Actions.list[1],
                    child: Center(
                        child: Text(Actions.list[1].title,
                            style: TextStyle(color: Actions.list[1].textColor, fontWeight: FontWeight.bold)))),
                DropdownMenuItem<myAction.Action>(
                    value: Actions.list[2],
                    child: Center(
                        child: Text(Actions.list[2].title,
                            style: TextStyle(color: Actions.list[2].textColor, fontWeight: FontWeight.bold))))
              ]),
          )),
        ),
        TablesDropdown(widget.actions.current, widget.dbModel)
      ],
    );
  }
}

class TablesDropdown extends StatefulWidget {
  TablesDropdown(this.action, this.dbModel);

  final myAction.Action action; // TODO will be a class
  final DatabaseModel dbModel;

  @override
  _TablesDropdownState createState() => _TablesDropdownState();
}

class _TablesDropdownState extends State<TablesDropdown> {
  var tables = <my.Table>[];
  my.Table selectedTable;
  PropertiesForm form;
  final _formBloc = FormBloc();

  @override
  void initState() {
    super.initState();
    tables = widget.dbModel.tables;
    selectedTable = tables[0];    // TODO I should access persistent data here
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
              child: Icon(Icons.check, color: widget.action.textColor,),
              onPressed: () {
                if (form.formKey.currentState.validate()) {
                  _formBloc.add(SubmitFormEvent(
                      context, form.propertiesForm, widget.action.title, selectedTable));
                }
                else {
                  final snackBar = SnackBar(
                    content: Text("Check for wrong input"),
                    backgroundColor: Colors.red,
                  );
                  Scaffold.of(context).showSnackBar(snackBar);
                }
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
        color: Colors.grey[300],
        child: DropdownButtonHideUnderline(
            child: Theme(
              data: ThemeData(canvasColor: Colors.grey[300]),
              child: DropdownButton<String>(
                  value: selectedTable.name,
                  iconSize: 0,
                  elevation: 0,
                  isExpanded: true,
                  onChanged: (String newValue) {
                    setState(() {
                      selectedTable = tables
                          .where((t) => t.name == newValue)
                          .first; // TODO not very clean
                    });
                  },
                  items: tables.map<DropdownMenuItem<String>>((my.Table table) {
                    return DropdownMenuItem<String>(
                        value: table.name,
                        child: Center(
                            child: Text(table.name,
                                style: TextStyle(color: Colors.black))));
                  }).toList()),
            )),
      )
      ,
    );
  }
}
