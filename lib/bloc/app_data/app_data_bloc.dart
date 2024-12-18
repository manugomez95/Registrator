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
            final password = c['password'] as String;
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
            db.databaseBloc.add(ConnectToDatabase(db, fromForm: false));
            debugPrint('Added connection: ${c['alias']}');
          } catch (e, stackTrace) {
            debugPrint('Error loading connection ${c['alias']}: $e');
            debugPrint(stackTrace.toString());
            continue;
          }
        }

        emit(InitCompleted(loadingStack));
      } catch (e, stackTrace) {
        debugPrint('Error initializing app data: $e');
        debugPrint(stackTrace.toString());
        emit(InitCompleted(loadingStack));
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
}
