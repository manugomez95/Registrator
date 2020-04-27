import 'package:bitacora/bloc/app_data/app_data_state.dart';
import 'package:bitacora/bloc/database/database_event.dart';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/main.dart';
import 'package:bitacora/model/app_data.dart';
import 'package:bitacora/ui/components/database_card.dart';
import 'package:bitacora/ui/components/db_form.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bitacora/conf/style.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DataPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => DataPageState();
}

class DataPageState extends State<DataPage> {
  final DbForm dbForm = DbForm();
  Map<DbClient, bool> isExpanded = {};

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (BuildContext context) => getIt<AppData>().bloc,
        child: BlocBuilder(
          bloc: getIt<AppData>().bloc,
          builder: (BuildContext context, AppDataState state) {
            List<DbClient> dbs = getIt<AppData>().dbs.toList();
            return Scaffold(
              body: RefreshIndicator(
                child: ListView(
                  children: <Widget>[
                    ExpansionPanelList(
                        children: dbs
                            .map((DbClient db) => ExpansionPanel(
                          canTapOnHeader: true,
                          headerBuilder:
                              (BuildContext context, bool isExpanded) {
                            return DatabaseCardHeader(db);
                          },
                          isExpanded: isExpanded[db] ?? false,
                          body: new Container(
                            child: DatabaseCardBody(db),
                          ),
                        ))
                            .toList(),
                        expansionCallback: (int index, bool isExpanded) {
                          setState(() {
                            this.isExpanded[dbs[index]] = !isExpanded;
                          });
                        }),
                    /// It allows to scroll a bit further so the floating action button doesn't bother
                    SizedBox(height: 50,)
                  ],
                ),
                onRefresh: () async {
                  getIt<AppData>()
                      .dbs
                      .forEach((db) => db.databaseBloc.add(UpdateDbStatus(db)));
                },
              ),
              floatingActionButton: FloatingActionButton(
                child: Icon(Icons.add),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                            title: Text("Add Postgres DB"),
                            content: dbForm,
                            actions: <Widget>[
                              FlatButton(
                                child: Text('Cancel',
                                    style: Theme.of(context).textTheme.button.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .defaultTextColor)),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              RaisedButton(
                                child: Text('Submit'),
                                onPressed: () {
                                  if (dbForm.formKey.currentState.validate()) {
                                    dbForm.submit(context);
                                  }
                                },
                              )
                            ]);
                      });
                },
              ),
            );
          },
        ));
  }
}
