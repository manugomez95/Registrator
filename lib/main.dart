import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:registrator/dbClients/postgres_client.dart';
import 'ui/destination.dart';
import 'ui/destinationView.dart';

GetIt getIt = GetIt.asNewInstance();

Future<void> main() async {
  getIt.registerSingleton<PostgresClient>(await PostgresClient.create());
  runApp(MyApp());
}

// TODO not closing db connection for the moment
class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registrator',
      theme: ThemeData(primaryColor: Colors.white),
      home: Routing(),
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
  LinkedHashSet<int> _pStack = LinkedHashSet(); // TODO "stack set"

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
        bottomNavigationBar: new BottomNavigationBar(
          items: allDestinations.map((Destination destination) {
            return BottomNavigationBarItem(
                icon: Icon(destination.icon), title: Text(destination.title));
          }).toList(),
          currentIndex: _selectedIndex,
          selectedItemColor: Color.fromRGBO(80, 158, 227, 1),
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
