import 'package:bitacora/model/property.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bitacora/ui/components/property_view.dart';
import 'package:tuple/tuple.dart';
import 'package:bitacora/model/action.dart' as app;
import 'package:bitacora/model/table.dart' as app;

class PropertiesForm extends StatelessWidget {
  PropertiesForm(this.table, this.action);

  final app.Table table;
  final app.Action action;
  final formKey = GlobalKey<FormState>();

  // Name, value
  final Map<String, String> propertiesForm = {};

  void tableUpdater(Tuple2<String, String> newProperty) {
    propertiesForm[newProperty.item1] = newProperty.item2;
  }

  @override
  Widget build(BuildContext context) {
    List<Property> properties = table.properties.toList();

    // get last row... TODO shouldn't be async?
    table.client.getLastRow(table);

    return Form(
      key: formKey,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: table.properties.length,
        padding: new EdgeInsets.all(15),
        separatorBuilder: (BuildContext context, int index) => Divider(height: 20,),
        itemBuilder: (BuildContext context, int index) {
          return PropertyView(properties[index], tableUpdater, action);
        },
      ),
    );
  }
}