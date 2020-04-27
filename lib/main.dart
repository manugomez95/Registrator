import 'dart:collection';

import 'package:bitacora/conf/style.dart';
import 'package:bitacora/model/action.dart' as app;
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
import 'package:dynamic_theme/dynamic_theme.dart';

GetIt getIt = GetIt.asNewInstance();

Future<void> main() async {
  // TODO get all saved connections
  getIt.registerSingleton<AppData>(AppData());
  // get AppData
  // for each dbClient recovered
  // - try connecting
  var db1 = PostgresClient(PgConnectionParams("My data", "192.168.1.14", 5432,
      "my_data", "postgres", r"!$36<BD5vuP7", true));
  var db2 = PostgresClient(PgConnectionParams("Alfred", "192.168.1.18", 5433,
      "postgres", "postgres", r"unit679City", false));
  var db3 = PostgresClient(PgConnectionParams("Empty", "192.168.1.14", 5432,
      "postgres", "postgres", r"!$36<BD5vuP7", true));
  db1.databaseBloc.add(ConnectToDatabase(db1));
  db2.databaseBloc.add(ConnectToDatabase(db2));
  db2.databaseBloc.add(ConnectToDatabase(db3));
  getIt<AppData>().dbs.add(db1);
  getIt<AppData>().dbs.add(db2);
  getIt<AppData>().dbs.add(db3);

  runApp(MyApp());
}

// TODO not closing db connection for the moment
class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DynamicTheme(
        defaultBrightness: Brightness.light,
        data: (brightness) => brightness == Brightness.light ? Themes.lightTheme : Themes.darkTheme,
        themedWidgetBuilder: (context, theme) {
          return MaterialApp(
            title: 'bitacora',
            theme: theme,
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
        });
  }
}

class Routing extends StatefulWidget {
  @override
  RoutingState createState() => new RoutingState();
}

// SingleTickerProviderStateMixin is used for animation
class RoutingState extends State<Routing> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Scaffold(
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
          selectedItemColor: theme.colorScheme.secondary,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
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
