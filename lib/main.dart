import 'dart:collection';

import 'package:bitacora/conf/style.dart' as app;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'bloc/database/database_event.dart';
import 'db_clients/postgres_client.dart';
import 'model/app_data.dart';
import 'ui/destination.dart';
import 'ui/destination_view.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bitacora/utils/db_parameter.dart';

GetIt getIt = GetIt.asNewInstance();

Future<void> main() async {
  // TODO get all saved connections
  getIt.registerSingleton<AppData>(AppData());
  // get AppData
  // for each dbClient recovered
  // - try connecting

  var db1 = PostgresClient(PostgreSQL("My data", "192.168.1.14", 5432, "my_data", "postgres", r"!$36<BD5vuP7", true));
  var db2 = PostgresClient(PostgreSQL("Alfred", "192.168.1.18", 5433, "postgres", "postgres", r"unit679City", false));
  db1.databaseBloc.add(ConnectToDatabase(db1));
  db2.databaseBloc.add(ConnectToDatabase(db2));
  getIt<AppData>().dbs.add(db1);
  getIt<AppData>().dbs.add(db2);
  runApp(MyApp());
}

// TODO not closing db connection for the moment
class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'bitacora',
      theme: ThemeData(
          primaryColor: Colors.white,
          brightness: Brightness.light,
          inputDecorationTheme: InputDecorationTheme(
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent, width: 2)
            )
          )
      ),
      home: Routing(),
      localizationsDelegates: [
        // ... app-specific localization delegate[s] here
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en'), // English
        const Locale('es'), // Spanish
        const Locale('fr'), // French
        const Locale('zh'), // Chinese
      ],
    );
  }
}

class Routing extends StatefulWidget {
  @override
  RoutingState createState() => new RoutingState();
}

// SingleTickerProviderStateMixin is used for animation
class RoutingState extends State<Routing> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  LinkedHashSet<int> _pStack = LinkedHashSet();

  // ignore: missing_return
  Future<bool> _onWillPop() {
    setState(() {
      if (_pStack.isEmpty)
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      // Pop
      _selectedIndex = _pStack.last;
      _pStack.remove(_selectedIndex);
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      // push
      if (_pStack.contains(index)) _pStack.remove(index);
      _pStack.add(_selectedIndex);
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: new Scaffold(
        body: SafeArea(
          top: false,
          child: IndexedStack(
            index: _selectedIndex,
            children: allDestinations.map<Widget>((Destination destination) {
              return DestinationView(destination: destination);
            }).toList(),
          ),
        ),
        // drawer: new AppNavigationDrawer(),
        bottomNavigationBar: BottomNavigationBar(
          items: allDestinations.map((Destination destination) {
            return BottomNavigationBarItem(
                icon: Icon(destination.icon), title: Text(destination.title));
          }).toList(),
          currentIndex: _selectedIndex,
          selectedItemColor: app.Style.navigationBlue,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

Widget noConnectionBanner() {
  return Material(
    child: Container(
      padding: EdgeInsets.all(5),
      child: Text("Not connected",
          style: TextStyle(
            color: Colors.white,
          ),
          textAlign: TextAlign.center),
      color: Colors.grey[800],
    ),
  );
}
