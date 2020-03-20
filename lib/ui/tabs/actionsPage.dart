import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:postgres/postgres.dart';
import 'package:registrator/bloc/database_model/bloc.dart';
import 'package:registrator/model/databaseModel.dart';
import 'package:registrator/model/property.dart';
import 'package:registrator/model/table.dart' as my;
import 'package:registrator/postgresClient.dart';
import 'package:registrator/ui/date_picker.dart';
import 'package:rxdart/rxdart.dart';
import 'package:get_it/get_it.dart';
import 'package:tuple/tuple.dart';

GetIt getIt = GetIt.instance;

class ActionsPage extends StatefulWidget {
  const ActionsPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ActionsPageState();
}

class ActionsPageState extends State<ActionsPage> {
  final actions = Actions();
  final dbModelBloc = DatabaseModelBloc();

  @override
  void initState() {
    super.initState();

    dbModelBloc.add(GetDatabaseModel("my_data")); // TODO this will change
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (BuildContext context) => dbModelBloc,
        child: BlocBuilder(
          bloc: dbModelBloc,
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
      body: ActionsDropdown(actions, dbModel),
    );
  }

  @override
  void dispose() async {
    super.dispose();
    await dbModelBloc.close();
  }
}

class Actions {
  static const list = <String>[
    'INSERT INTO',
    'EDIT LAST FROM',
    'CREATE WIDGET FROM'
  ];
  BehaviorSubject _selectedAction = BehaviorSubject.seeded(list[0]);
  Stream get stream$ => _selectedAction.stream;
  String get current => _selectedAction.value;
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
  void initState() {
    super.initState();
    getIt.registerSingleton<Actions>(widget.actions);
  }

  @override
  // TODO change with actions class
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        DropdownButtonHideUnderline(
            child: DropdownButton<String>(
                value: widget.actions.current,
                iconSize: 0,
                elevation: 0,
                isExpanded: true,
                onChanged: (String newValue) {
                  setState(() {
                    widget.actions.select(newValue);
                  });
                },
                items: [
              DropdownMenuItem<String>(
                  value: Actions.list[0],
                  child: Container(
                      child: Center(
                          child: Text(Actions.list[0],
                              style: TextStyle(color: Colors.white))),
                      color: Colors.blue,
                      height: kToolbarHeight)),
              DropdownMenuItem<String>(
                  value: Actions.list[1],
                  child: Container(
                      child: Center(
                          child: Text(Actions.list[1],
                              style: TextStyle(color: Colors.black))),
                      color: Colors.amber,
                      height: kToolbarHeight)),
              DropdownMenuItem<String>(
                  value: Actions.list[2],
                  child: Container(
                      child: Center(
                          child: Text(Actions.list[2],
                              style: TextStyle(color: Colors.white))),
                      color: Colors.green,
                      height: kToolbarHeight))
            ])),
        TablesDropdown(widget.actions.current, widget.dbModel)
      ],
    );
  }
}

class TablesDropdown extends StatefulWidget {
  TablesDropdown(this.action, this.dbModel);

  final String action; // TODO will be a class
  final DatabaseModel dbModel;

  @override
  _TablesDropdownState createState() => _TablesDropdownState();
}

class _TablesDropdownState extends State<TablesDropdown> {
  var tables = <my.Table>[];
  my.Table selectedTable;
  PropertiesForm form;

  @override
  void initState() {
    super.initState();
    tables = widget.dbModel.tables;
    selectedTable = tables[0];
    buildPropertiesForm(selectedTable, widget.action);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Scaffold(
        appBar: buildTablesDropdown(),
        body: buildPropertiesForm(selectedTable, widget.action),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            tooltip: "${widget.action} ${selectedTable.name}",
            child: Icon(Icons.check),
            onPressed: () {
              form.submit(context, selectedTable, widget.action);
            },
          ),
        ),
      ),
    );
  }

  PropertiesForm buildPropertiesForm(selectedTable, action) {
    form = PropertiesForm(selectedTable, action);
    return form;
  }

  Widget buildTablesDropdown() {
    return PreferredSize(
      preferredSize: Size(double.infinity, kToolbarHeight),
      child: DropdownButtonHideUnderline(
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
                    child: Container(
                        child: Center(
                            child: Text(table.name,
                                style: TextStyle(color: Colors.black))),
                        color: Colors.grey[300],
                        height: kToolbarHeight));
              }).toList())),
    );
  }
}

class PropertiesForm extends StatelessWidget {
  PropertiesForm(this.table, this.action);

  final my.Table table;
  final String action;

  final _formKey = GlobalKey<FormState>();

  // Name, value
  final Map<String, String> propertiesForm = {};

  void tableUpdater(Tuple2<String, String> newProperty) {
    propertiesForm[newProperty.item1] = newProperty.item2;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView.separated(
        itemCount: table.properties.length,
        padding: new EdgeInsets.all(8.0),
        separatorBuilder: (BuildContext context, int index) => Divider(),
        itemBuilder: (BuildContext context, int index) {
          return PropertyView(table.properties[index], tableUpdater);
        },
      ),
    );
  }

  // TODO submit should call the bloc
  bool submit(BuildContext context, my.Table selectedTable, String action) {
    final snackBar = SnackBar(
        content: Text("$action ${selectedTable.name} done!"),
        action: SnackBarAction(
          label: "Undo",
          onPressed: () {
            // Some code to undo the change.
          },
        ));
    Scaffold.of(context).showSnackBar(snackBar);
    print(propertiesForm);
    PostgresClient.insertRowIntoTable(null, table.name, propertiesForm);
    return true;
  }
}

class PropertyView extends StatefulWidget {
  PropertyView(this.property, this.updater);

  final Property property;
  final ValueChanged<Tuple2<String, String>> updater;

  @override
  State<StatefulWidget> createState() => _PropertyViewState();
}

class _PropertyViewState extends State<PropertyView>
    with AutomaticKeepAliveClientMixin {
  var value;

  void updateForm(String value, PostgreSQLDataType dataType) {
    if ([PostgreSQLDataType.text, PostgreSQLDataType.date, PostgreSQLDataType.uuid].contains(dataType))
      value = "'$value'";

    if (widget.updater != null)
      widget.updater(Tuple2(widget.property.name, value));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              widget.property.name,
              style: new TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 19.0,
              ),
            ),
            SizedBox(width: 50),
            Text(widget.property.type.toString().split(".").last)
          ],
        ),
        buildInput(widget.property.type)
      ],
    );
  }

  void _onChangeController(newValue, dataType) {
    setState(() {
      value = newValue;
      updateForm(value, dataType);
    });
  }

  Widget buildInput(PostgreSQLDataType dataType) {
    Widget ret;
    if (dataType == PostgreSQLDataType.text) {
      ret = TextField(
        onChanged: (newValue) => _onChangeController(newValue, dataType),
      );
    } else if ([
      PostgreSQLDataType.real,
      PostgreSQLDataType.smallInteger,
      PostgreSQLDataType.integer,
      PostgreSQLDataType.bigInteger
    ].contains(dataType)) {
      value = value == null ? "" : value;
      ret = TextField(
          keyboardType: TextInputType.number,
          onChanged: (newValue) => _onChangeController(newValue, dataType),
          decoration: new InputDecoration.collapsed(hintText: '0')
      );
    } else if (dataType == PostgreSQLDataType.boolean) {
        value = value == null ? false : value;
      ret = Checkbox(
        value: value,
        onChanged: (newValue) => _onChangeController(newValue, dataType),
      );
    } else if (dataType == PostgreSQLDataType.date) {
      value = value == null ? "2020-03-20" : value;
      ret = DatePicker(showDate: true);
    } else if ([
      PostgreSQLDataType.timestampWithTimezone,
      PostgreSQLDataType.timestampWithoutTimezone
    ].contains(dataType)) {
      value = value == null? DateTime.now().millisecondsSinceEpoch : value;
      ret = DatePicker(
        showDate: true,
        showTime: true,
      );
    }
    updateForm(value, dataType);
    return ret;
  }

  @override
  bool get wantKeepAlive => true;
}
