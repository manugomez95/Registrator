import 'package:bitacora/ui/pages/data_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import './pages/actions_page.dart';

@immutable
class Destination {
  const Destination(this.title, this.icon, this.page);
  
  final String title;
  final IconData icon;
  final Widget page;
}

final List<Destination> allDestinations = <Destination>[
  Destination('Actions', Icons.flash_on, ActionsPage()),
  Destination('Data', Icons.storage, DataPage()),
];