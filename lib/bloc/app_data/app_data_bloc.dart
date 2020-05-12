import 'dart:async';
import 'package:bitacora/bloc/database/database_event.dart';
import 'package:bitacora/db_clients/bigquery_client.dart';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:bitacora/db_clients/sqlite_client.dart';
import 'package:bitacora/main.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:bloc/bloc.dart';
import './bloc.dart';
import 'package:stack/stack.dart';
import 'package:bitacora/model/app_data.dart';
import 'package:simple_rsa/simple_rsa.dart';

class AppDataBloc extends Bloc<AppDataEvent, AppDataState> {
  Stack<AppDataEvent> loadingStack = Stack();

  final PRIVATE_KEY =
      "MIIEoQIBAAKCAQBuAGGBgg9nuf6D2c5AIHc8vZ6KoVwd0imeFVYbpMdgv4yYi5ob" +
          "tB/VYqLryLsucZLFeko+q1fi871ZzGjFtYXY9Hh1Q5e10E5hwN1Tx6nIlIztrh5S" +
          "9uV4uzAR47k2nng7hh6vuZ33kak2hY940RSLH5l9E5cKoUXuQNtrIKTS4kPZ5IOU" +
          "SxZ5xfWBXWoldhe+Nk7VIxxL97Tk0BjM0fJ38rBwv3++eAZxwZoLNmHx9wF92XKG" +
          "+26I+gVGKKagyToU/xEjIqlpuZ90zesYdjV+u0iQjowgbzt3ASOnvJSpJu/oJ6Xr" +
          "WR3egPoTSx+HyX1dKv9+q7uLl6pXqGVVNs+/AgMBAAECggEANG9qC1n8De3TLPa+" +
          "IkNXk1SwJlUUnAJ6ZCi3iyXZBH1Kf8zMATizk/wYvVxKHbF1zTyl94mls0GMmSmf" +
          "J9+Hlguy//LgdoJ9Wouc9TrP7BUjuIivW8zlRc+08lIjD64qkfU0238XldORXbP8" +
          "2BKSQF8nwz97WE3YD+JKtZ4x83PX7hqC9zabLFIwFIbmJ4boeXzj4zl8B7tjuAPq" +
          "R3JNxxKfvhpqPcGFE2Gd67KJrhcH5FIja4H/cNKjatKFcP6qNfCA7e+bua6bL0Cy" +
          "DzmmNSgz6rx6bthcJ65IKUVrJK6Y0sBcNQCAjqZDA0Bs/7ShGDL28REuCS1/udQz" +
          "XyB7gQKBgQCrgy2pvqLREaOjdds6s1gbkeEsYo7wYlF4vFPg4sLIYeAt+ed0kn4N" +
          "dSmtp4FXgGyNwg7WJEveKEW7IEAMQBSN0KthZU4sK9NEu2lW5ip9Mj0uzyUzU4lh" +
          "B+zwKzZCorip/LIiOocFWtz9jwGZPCKC8expUEbMuU1PzlxrytHJaQKBgQCkMEci" +
          "EHL0KF5mcZbQVeLaRuecQGI5JS4KcCRab24dGDt+EOKYchdzNdXdM8gCHNXb8RKY" +
          "NYnHbCjheXHxV9Jo1is/Qi9nND5sT54gjfrHMKTWAtWKAaX55qKG0CEyBB87WqJM" +
          "Ydn7i4Rf0rsRNa1lbxQ+btX14d0xol9313VC5wKBgERD6Rfn9dwrHivAjCq4GXiX" +
          "vr0w2V3adD0PEH+xIgAp3NXP4w0mBaALozQoOLYAOrTNqaQYPE5HT0Hk2zlFBClS" +
          "BfS1IsE4DFYOFiZtZDoClhGch1z/ge2p/ue0+1rYc5HNL4WqL/W0rcMKeYNpSP8/" +
          "lW5xckyn8Jq0M1sAFjIJAoGAQJvS0f/BDHz6MLvQCelSHGy8ZUscm7oatPbOB1xD" +
          "62UGvCPu1uhGfAqaPrJKqTIpoaPqmkSvE+9m4tsEUGErph9o4zqrJqRzT/HAmrTk" +
          "Ew/8PU7eMrFVW9I68GvkNCdVFukiZoY23fpXu9FT1YDW28xrHepFfb1EamynvqPl" +
          "O88CgYAvzzSt+d4FG03jwObhdZrmZxaJk0jkKu3JkxUmav9Zav3fDTX1hYxDNTLi" +
          "dazvUFfqN7wqSSPqajQmMoTySxmLI8gI4qC0QskB4lT1A8OfmjcDwbUzQGam5Kpz" +
          "ymmKJA9DgQpPgEIjHAnw2dUDR+wI/Loywb0AGLIbszseCOlc2Q==";

  @override
  AppDataState get initialState => Loading(loadingStack);

  @override
  Stream<AppDataState> mapEventToState(
    AppDataEvent event,
  ) async* {
    if (event is InitializeEvent) {
      await getIt<AppData>().initLocalDb();

      await BigQueryClient(DbConnectionParams("","",0,"","","",false)).connect();

      /// Connect to saved connections
      for (var c in await getIt<AppData>().localDb.query('connections')) {
        var password = await decryptString(c["password"], PRIVATE_KEY);
        var connectionParams = DbConnectionParams(
            c["alias"],
            c["host"],
            c["port"],
            c["db_name"],
            c["username"],
            password,
            c["ssl"] == 0 ? false : true);
        DbClient db;
        switch (c["brand"]) {
          case "postgres":
            db = PostgresClient(connectionParams);
            break;
          case "sqlite_android":
            db = SQLiteClient(connectionParams);
            break;
          default:
            throw Exception("brand not supported");
        }
        db.databaseBloc.add(ConnectToDatabase(db));
        getIt<AppData>().dbs.add(db);
      }

      yield InitCompleted(loadingStack);
    }
    if (event is UpdateUIEvent) {
      if (loadingStack.isNotEmpty) loadingStack.pop();
      yield UpdateUI(event, loadingStack);
    } else if (event is LoadingEvent) {
      loadingStack.push(event);
      yield Loading(loadingStack);
    }
  }
}
