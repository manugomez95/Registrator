import 'package:bitacora/main.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
            color: Theme.of(context).colorScheme.defaultTextColor),
        title: Text(widget.destination.title,
            style: TextStyle(
                color: Theme.of(context).colorScheme.defaultTextColor)),
        actions: <Widget>[
          PopupMenuButton<int>(
              itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 1,
                      child: Text("Change theme"),
                    ),
                    PopupMenuItem(
                      value: 2,
                      child: Text("About"),
                    ),
                  ],
              onSelected: (value) {
                switch (value) {
                  case 1:
                    setState(() {
                      DynamicTheme.of(context).setBrightness(
                          Theme.of(context).brightness == Brightness.dark
                              ? Brightness.light
                              : Brightness.dark);
                    });
                    break;
                  case 2:
                    showAboutDialog(
                        context: context,
                        applicationVersion: "0.1.0",
                        applicationIcon: Image.asset('assets/logo.png',
                            height: 40, width: 40,));
                    break;
                  default:
                }
              })
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
