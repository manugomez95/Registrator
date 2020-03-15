import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:registrator/ui/tabs/dashboardPage.dart';
import '../assets/my_custom_icons.dart';
import './tabs/actionsPage.dart';

class Destination {
  const Destination(this.title, this.icon, this.page);
  final String title;
  final IconData icon;
  final Widget page;
}

const List<Destination> allDestinations = <Destination>[
  Destination('Actions', Icons.flash_on, Dropdowns()),
  Destination('Dashboard', Icons.dashboard, DashboardPage()),
  Destination('Data', MyCustomIcons.database, null),
];