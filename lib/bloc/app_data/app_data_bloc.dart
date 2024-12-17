import 'dart:async';
import 'dart:convert';
import 'package:bitacora/bloc/database/database_event.dart';
import 'package:bitacora/db_clients/bigquery_client.dart';
import 'package:bitacora/db_clients/db_client.dart';
import 'package:bitacora/db_clients/postgres_client.dart';
import 'package:bitacora/db_clients/sqlite_client.dart';
import 'package:bitacora/main.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:bloc/bloc.dart';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';
import './bloc.dart';
import 'package:stack/stack.dart';
import 'package:bitacora/model/app_data.dart';
import 'package:flutter/foundation.dart';

class AppDataBloc extends Bloc<AppDataEvent, AppDataState> {
  AppDataBloc() : super(Loading(Stack<AppDataEvent>())) {
    on<InitializeEvent>((event, emit) async {
      try {
        await getIt<AppData>().initLocalDb();

        // Connect to saved connections
        final connections = await getIt<AppData>().localDb.query('connections');
        debugPrint('Loading ${connections.length} saved connections');

        for (final c in connections) {
          try {
            final password = await _decryptString(c['password'] as String);
            final brand = c['brand'] as String;
            debugPrint('Loading connection: ${c['alias']} (${brand})');

            final connectionParams = DbConnectionParams(
              c['alias'] as String,
              c['host'] as String,
              c['port'] as int,
              c['db_name'] as String,
              c['username'] as String,
              password,
              c['ssl'] == 1,
              brand,
            );

            late final DbClient db;
            switch (brand) {
              case 'postgres':
                db = PostgresClient(connectionParams);
                break;
              case 'sqlite':
              case 'sqlite_android':
                db = SQLiteClient(connectionParams);
                break;
              case 'bigquery':
                db = BigQueryClient(connectionParams);
                break;
              default:
                throw Exception('Database brand $brand not supported');
            }

            getIt<AppData>().dbs.add(db);
            db.databaseBloc.add(ConnectToDatabase(db));
            debugPrint('Added connection: ${c['alias']}');
          } catch (e, stackTrace) {
            debugPrint('Error loading connection ${c['alias']}: $e');
            debugPrint(stackTrace.toString());
            // Continue loading other connections even if one fails
            continue;
          }
        }

        emit(InitCompleted(loadingStack));
      } catch (e, stackTrace) {
        debugPrint('Error initializing app data: $e');
        debugPrint(stackTrace.toString());
        emit(InitCompleted(loadingStack)); // Still mark as completed to not block the app
      }
    });

    on<UpdateUIEvent>((event, emit) {
      if (loadingStack.isNotEmpty) {
        loadingStack.pop();
      }
      emit(UpdateUI(event, loadingStack));
    });

    on<LoadingEvent>((event, emit) {
      loadingStack.push(event);
      emit(Loading(loadingStack));
    });
  }

  final Stack<AppDataEvent> loadingStack = Stack<AppDataEvent>();

  static const String _privateKeyPem = '''
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQBuAGGBgg9nuf6D
2c5AIHc8vZ6KoVwd0imeFVYbpMdgv4yYi5obtB/VYqLryLsucZLFeko+q1fi871Z
zGjFtYXY9Hh1Q5e10E5hwN1Tx6nIlIztrh5S9uV4uzAR47k2nng7hh6vuZ33kak2
hY940RSLH5l9E5cKoUXuQNtrIKTS4kPZ5IOUSxZ5xfWBXWoldhe+Nk7VIxxL97Tk
0BjM0fJ38rBwv3++eAZxwZoLNmHx9wF92XKG+26I+gVGKKagyToU/xEjIqlpuZ90
zesYdjV+u0iQjowgbzt3ASOnvJSpJu/oJ6XrWR3egPoTSx+HyX1dKv9+q7uLl6pX
qGVVNs+/AgMBAAECggEANG9qC1n8De3TLPa+IkNXk1SwJlUUnAJ6ZCi3iyXZBH1K
f8zMATizk/wYvVxKHbF1zTyl94mls0GMmSmfJ9+Hlguy//LgdoJ9Wouc9TrP7BUj
uIivW8zlRc+08lIjD64qkfU0238XldORXbP82BKSQF8nwz97WE3YD+JKtZ4x83PX
7hqC9zabLFIwFIbmJ4boeXzj4zl8B7tjuAPqR3JNxxKfvhpqPcGFE2Gd67KJrhcH
5FIja4H/cNKjatKFcP6qNfCA7e+bua6bL0CyDzmmNSgz6rx6bthcJ65IKUVrJK6Y
0sBcNQCAjqZDA0Bs/7ShGDL28REuCS1/udQzXyB7gQKBgQCrgy2pvqLREaOjdds6
s1gbkeEsYo7wYlF4vFPg4sLIYeAt+ed0kn4NdSmtp4FXgByNwg7WJEveKEW7IEAM
QBSN0KthZU4sK9NEu2lW5ip9Mj0uzyUzU4lhB+zwKzZCorip/LIiOocFWtz9jwGZ
PCKC8expUEbMuU1PzlxrytHJaQKBgQCkMEciEHL0KF5mcZbQVeLaRuecQGI5JS4K
cCRab24dGDt+EOKYchdzNdXdM8gCHNXb8RKYNYnHbCjheXHxV9Jo1is/Qi9nND5s
T54gjfrHMKTWAtWKAaX55qKG0CEyBB87WqJMYdn7i4Rf0rsRNa1lbxQ+btX14d0x
ol9313VC5wKBgERD6Rfn9dwrHivAjCq4GXiXvr0w2V3adD0PEH+xIgAp3NXP4w0m
BaALozQoOLYAOrTNqaQYPE5HT0Hk2zlFBClSBfS1IsE4DFYOFiZtZDoClhGch1z/
ge2p/ue0+1rYc5HNL4WqL/W0rcMKeYNpSP8/lW5xckyn8Jq0M1sAFjIJAoGAQJvS
0f/BDHz6MLvQCelSHGy8ZUscm7oatPbOB1xD62UGvCPu1uhGfAqaPrJKqTIpoaPq
mkSvE+9m4tsEUGErph9o4zqrJqRzT/HAmrTkEw/8PU7eMrFVW9I68GvkNCdVFuki
ZoY23fpXu9FT1YDW28xrHepFfb1EamynvqPlO88CgYAvzzSt+d4FG03jwObhdZrm
ZxaJk0jkKu3JkxUmav9Zav3fDTX1hYxDNTLidazvUFfqN7wqSSPqajQmMoTySxmL
I8gI4qC0QskB4lT1A8OfmjcDwbUzQGam5KpzymmKJA9DgQpPgEIjHAnw2dUDR+wI
/Loywb0AGLIbszseCOlc2Q==
-----END PRIVATE KEY-----''';

  Future<String> _decryptString(String encryptedBase64) async {
    try {
      final parser = RSAKeyParser();
      final privateKey = parser.parse(_privateKeyPem) as RSAPrivateKey;
      final encrypter = Encrypter(RSA(privateKey: privateKey));
      final encrypted = Encrypted.fromBase64(encryptedBase64);
      return encrypter.decrypt(encrypted);
    } catch (e) {
      debugPrint('Error decrypting string: $e');
      return encryptedBase64; // Return original string if decryption fails
    }
  }
}
