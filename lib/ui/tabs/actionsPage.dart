import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:registrator/bloc/database_model/bloc.dart';
import 'package:registrator/model/databaseModel.dart';
import 'package:registrator/model/property.dart';
import 'package:registrator/model/table.dart' as my;

class ActionsPage extends StatefulWidget {
  const ActionsPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ActionsPageState();
}

class ActionsPageState extends State<ActionsPage> {
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
              return buildColumn(state.dbModel);
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

  Widget buildColumn(DatabaseModel dbModel) { // TODO change name
    return Scaffold(
      appBar: ActionsDropdown(),
      body: TablesDropdown(dbModel),
    );
  }

  @override
  void dispose() async {
    super.dispose();
    await dbModelBloc.close();
  }
}

class ActionsDropdown extends StatefulWidget implements PreferredSizeWidget {
  ActionsDropdown({Key key}) : super(key: key);

  @override
  _ActionsDropdownState createState() => _ActionsDropdownState();

  @override
  Size get preferredSize => const Size(double.infinity, kToolbarHeight);
}

class _ActionsDropdownState extends State<ActionsDropdown> {
  String dropdownValue = 'INSERT INTO';

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
        child: DropdownButton<String>(
            value: dropdownValue,
            iconSize: 0,
            elevation: 0,
            isExpanded: true,
            onChanged: (String newValue) {
              setState(() {
                dropdownValue = newValue;
              });
            },
            items: [
          DropdownMenuItem<String>(
              value: 'INSERT INTO',
              child: Container(
                  child: Center(
                      child: Text('INSERT INTO',
                          style: TextStyle(color: Colors.white))),
                  color: Colors.blue,
                  height: kToolbarHeight)),
          DropdownMenuItem<String>(
              value: 'EDIT LAST FROM',
              child: Container(
                  child: Center(
                      child: Text('EDIT LAST FROM',
                          style: TextStyle(color: Colors.black))),
                  color: Colors.amber,
                  height: kToolbarHeight)),
          DropdownMenuItem<String>(
              value: 'CREATE WIDGET FROM',
              child: Container(
                  child: Center(
                      child: Text('CREATE WIDGET FROM',
                          style: TextStyle(color: Colors.white))),
                  color: Colors.green,
                  height: kToolbarHeight))
        ]));
  }
}

class TablesDropdown extends StatefulWidget {
  TablesDropdown(this.dbModel);

  final DatabaseModel dbModel; // TODO This db model is null

  @override
  _TablesDropdownState createState() => _TablesDropdownState();
}

class _TablesDropdownState extends State<TablesDropdown> {
  var _tables = <my.Table>[];
  my.Table selectedTable;

  @override
  void initState() {
    super.initState();
    _tables = widget.dbModel.tables;
    selectedTable = _tables[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: PropertiesForm(selectedTable.properties),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.check),
      ),
    );
  }

  Widget buildAppBar() {
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
                  selectedTable = _tables
                      .where((t) => t.name == newValue)
                      .first; // TODO not very clean
                });
              },
              items: _tables.map<DropdownMenuItem<String>>((my.Table table) {
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

class PropertiesForm extends StatefulWidget {
  PropertiesForm(this.properties);

  final List<Property> properties;

  @override
  State<StatefulWidget> createState() => _PropertiesFormState();
}

class _PropertiesFormState extends State<PropertiesForm> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: new EdgeInsets.all(8.0),
        child: Column(
          children: widget.properties.map<PropertyView>((Property property) {
            return PropertyView(property);
          }).toList(),
        ));
  }
}

class PropertyView extends StatefulWidget {
  PropertyView(this.property);

  final Property property;

  @override
  State<StatefulWidget> createState() => _PropertyViewState();
}

class _PropertyViewState extends State<PropertyView> {
  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}
