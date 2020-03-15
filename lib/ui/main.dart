import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stack/stack.dart' as dataStack;

import 'destination.dart';
import 'destinationView.dart';

void main() {
  runApp(MyApp());
}

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
  dataStack.Stack<int> _pStack = dataStack.Stack(); // TODO "stack set"
  // TODO var dbClient;

  @override
  void initState() {
    super.initState();
    // TODO dbClient = await PostgresClient.create();
  }

  Future<bool> _onWillPop() {
    setState(() {
      if (_pStack.isEmpty) SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      _selectedIndex=_pStack.pop();
    });

  }

  void _onItemTapped(int index) {
    setState(() {
      _pStack.push(_selectedIndex);
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
                icon: Icon(destination.icon),
                title: Text(destination.title)
            );
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