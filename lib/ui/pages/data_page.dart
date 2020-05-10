import 'package:bitacora/bloc/app_data/app_data_state.dart';
import 'package:bitacora/bloc/database/database_event.dart';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/main.dart';
import 'package:bitacora/model/app_data.dart';
import 'package:bitacora/ui/components/database_card.dart';
import 'package:bitacora/ui/components/db_form.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DataPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => DataPageState();
}

class DataPageState extends State<DataPage> {
  Map<DbClient, bool> isExpanded = {};

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (BuildContext context) => getIt<AppData>().bloc,
        child: BlocBuilder(
          bloc: getIt<AppData>().bloc,
          builder: (BuildContext context, AppDataState state) {
            List<DbClient> dbs = getIt<AppData>().dbs.toList();
            isExpanded.removeWhere((key, value) => !dbs.contains(key));
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
                heroTag: "DataPageFB",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DbForm(DbFormType.connect), fullscreenDialog: true),
                  );
                },
              ),
            );
          },
        ));
  }
}
