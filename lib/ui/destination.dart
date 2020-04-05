import 'package:bitacora/ui/pages/data_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import './pages/actions_page.dart';

class Destination {
  const Destination(this.title, this.icon, this.page);
  final String title;
  final IconData icon;
  final Widget page;
}

const List<Destination> allDestinations = <Destination>[
  Destination('Actions', Icons.flash_on, ActionsPage()),
  Destination('Dashboard', Icons.dashboard, null),
  Destination('Data', Icons.storage, DataPage()),
];