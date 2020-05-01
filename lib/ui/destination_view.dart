import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'destination.dart';
import 'package:bitacora/conf/style.dart';

class DestinationView extends StatefulWidget {
  const DestinationView({Key key, this.destination}) : super(key: key);

  final Destination destination;

  @override
  _DestinationViewState createState() => _DestinationViewState();
}

class _DestinationViewState extends State<DestinationView> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.appBarColor,
        actionsIconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.defaultTextColor
        ),
        title: Text(widget.destination.title, style: TextStyle(color: Theme.of(context).colorScheme.defaultTextColor)),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.brightness_3),
            onPressed: () {
              setState(() {
                DynamicTheme.of(context).setBrightness(Theme.of(context).brightness == Brightness.dark? Brightness.light: Brightness.dark);
              });
            },
          )
        ],
      ),
      body: widget.destination.page,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
