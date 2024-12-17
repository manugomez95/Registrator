import 'package:bitacora/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'destination.dart';
import 'package:bitacora/conf/style.dart';

class DestinationView extends StatefulWidget {
  const DestinationView({
    super.key,
    required this.destination,
  });

  final Destination destination;

  @override
  _DestinationViewState createState() => _DestinationViewState();
}

class _DestinationViewState extends State<DestinationView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.appBarColor,
        actionsIconTheme: IconThemeData(
          color: theme.colorScheme.defaultTextColor,
        ),
        title: Text(
          widget.destination.title,
          style: TextStyle(
            color: theme.colorScheme.defaultTextColor,
          ),
        ),
        actions: <Widget>[
          PopupMenuButton<int>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 1,
                child: Text("Change theme"),
              ),
              const PopupMenuItem(
                value: 2,
                child: Text("About"),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 1:
                  setState(() {});
                  break;
                case 2:
                  showAboutDialog(
                    context: context,
                    applicationVersion: "0.1.0",
                    applicationIcon: Image.asset(
                      'assets/logo.png',
                      height: 40,
                      width: 40,
                    ),
                  );
                  break;
              }
            },
          ),
        ],
      ),
      body: widget.destination.page,
    );
  }
}
