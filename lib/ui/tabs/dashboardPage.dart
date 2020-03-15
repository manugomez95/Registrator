import 'package:flutter/material.dart';
import 'package:registrator/postgresClient.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage();

  @override
  _DashboardPageState createState() {
    return new _DashboardPageState();
  }
}

class _DashboardPageState extends State<DashboardPage> {
  String _textFromFile = "Hola";

  _DashboardPageState() {
    PostgresClient.getPropertiesFromTable("movies").then((val) => setState(() {
      print(val);
      _textFromFile = val.toString();
    }));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: new EdgeInsets.all(8.0),
      child: new Text(
        _textFromFile,
        style: new TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 19.0,
        ),
      ),
    );
  }
}