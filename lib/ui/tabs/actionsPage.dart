import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../postgresClient.dart';

var table = "";

class Dropdowns extends StatelessWidget implements PreferredSizeWidget {
  const Dropdowns();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ActionsDropdown(),
        TablesDropdown()
      ],
    );
  }

  @override
  Size get preferredSize => const Size(double.infinity, kToolbarHeight*2);
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

class TablesDropdown extends StatefulWidget implements PreferredSizeWidget {
  TablesDropdown({Key key}) : super(key: key);

  @override
  _TablesDropdownState createState() => _TablesDropdownState();

  @override
  Size get preferredSize => const Size(double.infinity, kToolbarHeight);
}

class _TablesDropdownState extends State<TablesDropdown> {
  var _tables = <String>[];
  String selectedTable;

  _TablesDropdownState() {
    PostgresClient.getTables().then((val) => setState(() {
      print(val);
      _tables = val;
      selectedTable = _tables[0];
      table = selectedTable;
    }));
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
        child: DropdownButton<String>(
            value: selectedTable,
            iconSize: 0,
            elevation: 0,
            isExpanded: true,
            onChanged: (String newValue) {
              setState(() {
                selectedTable = newValue;
              });
            },
            items: _tables
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                  value: value,
                  child: Container(
                      child: Center(child: Text(value, style: TextStyle(color: Colors.black))),
                      color: Colors.grey[300],
                      height: kToolbarHeight
                  )
              );
            }).toList()
        ));
  }
}

class PropertiesForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PropertiesFormState();

}

class _PropertiesFormState extends State<PropertiesForm> {
  var properties;

  _PropertiesFormState() {
    PostgresClient.getPropertiesFromTable(table).then((val) => setState(() {
      print(val);
      properties = val;
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Text(properties);
  }

}