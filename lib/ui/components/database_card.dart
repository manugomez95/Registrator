import 'package:bitacora/bloc/database/bloc.dart';
import 'package:bitacora/conf/style.dart';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';


final String assetName = 'assets/images/postgresql_elephant.svg';
final Widget svg = SvgPicture.asset(assetName,
    height: 75, width: 75, semanticsLabel: 'Postgres Logo');

// TODO improve layout so logo fills instead of having defined size
class DatabaseCard extends StatelessWidget {
  DatabaseCard(this.db);

  final DbClient db;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (BuildContext context) => db.databaseBloc,
        child: BlocBuilder(
          bloc: db.databaseBloc,
          builder: (BuildContext context, DatabaseState state) {
            Widget statusIcon;
            if (state is ConnectionSuccessful) {
              statusIcon = Icon(Icons.check, size: 18, color: Colors.green);
            }
            else if (state is ConnectionError) {
              statusIcon = Icon(Icons.error_outline, size: 18, color: Colors.redAccent);
            }
            else {
              statusIcon = SizedBox(
                child: CircularProgressIndicator(strokeWidth: 1,),
                height: 14.0,
                width: 14.0,
              );
              //statusIcon = Icon(Icons.sync, size: 18, color: Colors.blueAccent,);
            }
            return Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(15),
              color: Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    child: svg,
                    padding: EdgeInsets.only(left: 5, right: 25),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(bottom: 5),
                        child: Text(
                          db.params.alias,
                          style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: <Widget>[
                          Icon(
                            Icons.domain,
                            size: 18,
                          ),
                          Text(
                            db.params.host,
                            style: TextStyle(color: Style.grey, fontSize: 15),
                          )
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: <Widget>[
                          Icon(Icons.storage, size: 18),
                          Text(
                            db.params.dbName,
                            style: TextStyle(color: Style.grey, fontSize: 15),
                          )
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: <Widget>[
                          Icon(Icons.person, size: 18),
                          Text(
                            db.params.username,
                            style: TextStyle(color: Style.grey, fontSize: 15),
                          )
                        ],
                      ),
                    ],
                  ),
                  Spacer(),
                  statusIcon
                ],
              ),
            );
          },
        ));
  }
}
