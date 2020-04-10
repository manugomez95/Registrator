import 'package:bitacora/conf/style.dart';
import 'package:bitacora/main.dart';
import 'package:bitacora/model/app_data.dart';
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
    // TODO maybe can be optimized
    getIt<AppData>().dbs.forEach((db) {
      db.tables.forEach((t) {
        db.getLastRow(t);
      });
    });
    return Form(
      key: formKey,
      child: ListView.separated(
        itemCount: table.properties.length,
        padding: new EdgeInsets.all(Style.scaffoldPadding),
        separatorBuilder: (BuildContext context, int index) => Divider(height: 20,),
        itemBuilder: (BuildContext context, int index) {
          return PropertyView(properties[index], tableUpdater, action);
        },
      ),
    );
  }
}