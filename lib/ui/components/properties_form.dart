import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:registrator/model/table.dart' as my;
import 'package:registrator/ui/components/property_view.dart';
import 'package:tuple/tuple.dart';

class PropertiesForm extends StatelessWidget {
  PropertiesForm(this.table, this.action);

  final my.Table table;
  final String action;

  // TODO add validation
  final _formKey = GlobalKey<FormState>();

  // Name, value
  final Map<String, String> propertiesForm = {};

  void tableUpdater(Tuple2<String, String> newProperty) {
    propertiesForm[newProperty.item1] = newProperty.item2;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView.separated(
        itemCount: table.properties.length,
        padding: new EdgeInsets.all(15.0),
        separatorBuilder: (BuildContext context, int index) => Divider(),
        itemBuilder: (BuildContext context, int index) {
          return PropertyView(table.properties[index], tableUpdater);
        },
      ),
    );
  }
}