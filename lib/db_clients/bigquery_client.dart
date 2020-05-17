import 'dart:ui';

import 'package:bitacora/model/property.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:flutter_svg/svg.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:sqflite/sqflite.dart';
import 'db_client.dart';
import 'package:bitacora/model/table.dart' as app;

extension BQString on String {
  String pgFormat() {
    return this.toLowerCase() != this || this.contains(" ")
        ? '''"$this"'''
        : this;
  }

  static fromBQValue(dynamic value, DataType type, {bool fromArray = false}) {
    if (value == null || value.toString() == "")
      return 'null';
    else if (type.isArray && !fromArray)
      return (value as List).isEmpty
          ? 'null'
          : "'{${(value as List).map((e) => BQString.fromBQValue(e, type, fromArray: true)).join(", ")}}'";
    else {
      if ([
        PrimitiveType.text,
        PrimitiveType.varchar,
        PrimitiveType.date,
        PrimitiveType.timestamp,
        PrimitiveType.time,
      ].contains(type.primitive) && !fromArray)
        return "'${value.toString()}'";
      else
        return value.toString();
    }
  }

  DataType toDataType({String udtName, isArray: false}) {
    String arrayStr = isArray ? "[ ]" : "";
    switch (this) {
      case "TIMESTAMP":
        return DataType(PrimitiveType.timestamp, "timestamp" + arrayStr,
            isArray: isArray);
      case "TIME":
        return DataType(PrimitiveType.time, "time" + arrayStr,
            isArray: isArray);
      case "STRING":
        return DataType(PrimitiveType.text, "string" + arrayStr,
            isArray: isArray);
      case "INT64":
        return DataType(PrimitiveType.integer, "integer" + arrayStr,
            isArray: isArray);
      case "BOOL":
        return DataType(PrimitiveType.boolean, "boolean" + arrayStr,
            isArray: isArray);
      case "NUMERIC":
      case "FLOAT64":
        return DataType(PrimitiveType.real, "real" + arrayStr,
            isArray: isArray);
      case "DATE":
        return DataType(PrimitiveType.date, "date" + arrayStr,
            isArray: isArray);
      case "ARRAY": // TODO check
        return udtName.toDataType(isArray: true);
      default:
        throw UnsupportedError("$this not supported as a type");
    }
  }
}

// ignore: must_be_immutable
class BigQueryClient extends DbClient<BigqueryApi> {
  BigQueryClient(DbConnectionParams params, this.projectId, this.datasetId) : super(params);

  final String projectId;
  final String datasetId;

  @override
  Future<Map<String, dynamic>> toMap() async {
    Map<String, dynamic> params = await super.toMap();
    params["brand"] = "bigquery";
    return params;
  }

  @override
  cancelLastInsertion(app.Table table, Map<Property, dynamic> propertiesForm,
      {verbose = false}) {
    // TODO: implement cancelLastInsertion
    return null;
  }

  @override
  connect({verbose = false}) async {
    final _credentials = new ServiceAccountCredentials.fromJson(r'''{
      "type": "service_account",
      "project_id": "personal-analytics-270310",
      "private_key_id": "603b77d41b4e61cb997ee75bf2a33a22476535b0",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDLOBv6+Pj1g2KJ\n63gluqHcJ+lf9Y/E0rv1wHE+BH59lPAXVDsT4NQj9iweuilZ0g/u1g4dFoHfJOyf\n9Ux3u026ZSzFh1xneLMIlJpa/K+SlMq++hV3AX1Xt8iI7AKjtLojfsikgXIGmP1A\nndWdFNgVt0Mj8jljYwS6JSSopmmrHqfKMFrLALanSTcQkUSYv03YxHEuWYXh2bQy\nXtQUdcGBqvI2UVCtZ08+R6xhTv2TWFFxMrXh7BdNsfQ0oORsD3BitVwykPD7j8ai\nElGmzoU6Ryvnhqun//uIdUzssDJYhHmpB+Eil6/XovGPSRzqzRndbAPNchA1vmRn\nmatFfAVJAgMBAAECggEADtj5YF+W7vcruKhx1Y3afBeVazuphqef8H9gNrgE1t+O\nICI5E8V6Mmtuw0r2MPgSTnCoxNLLZ9aOjExTiy7t6aexOvheFbhBmmejFHFAUa0Z\n2BS1A0YiVomYtvpJYhUXAXdmqPBFOLquTC2L+SdX91Q1rVdp/nsyUfhbQpAwCb65\nBvY1/mIDDedPJqrfr8ZHpIp+c1Ya9ZnAYRhsIxwFT/7smuj4j/Rtx5v3IqBNpNwS\nOTpV+PoLVp7TRFeedE18FaQHUvxOdi2+m/yoCBLvbolstVNt/LfFlJUlz+WxDJaL\nxxZZ5Nu5jpKesK1jshFUfc5mQIYKZ0a4c1cjDsfxBQKBgQDuD1U5lJX2TesbdZLY\nzOi0J+8CV2Rku/U4zN8RB5HJCDnTgd6VjpxYxhAgSFPskl4lPiRrAYDUxZcyRYIr\nJbR8WsbY/mtHqpsL4uUNY3f6JUxrLPHTf2zvcHzSzXGutzLYrGbAp5QSZS7WUAzV\nF+1bMpNQLGKHUNnR1/FXB030fQKBgQDaiKCCNHqG03y2kpyraSUoNY0i7fiMetKP\nKOGaM7XgESyL9Fjh6ZwaKxTt8g/jwEK7hV/Jt5W0/V6YpparDrqiK6qdZoDfyJ/k\noxEya6AHj72ybVhRy4hnwJ/n5SDfAyPRNFUMXeWBfwIX472XLiY/YArjWZ3p8QJd\n3nIbwyipvQKBgQCTmsgyApIU/O0IwpbBfBPRGG2Wmw8xcmUyybyJt5LJ/iK0pPKY\n8qq4VF5NVetLZNmg5+32tyDlTHpZ/kUecat9618dzmpALmUiMpXo/kK2xAek8GIk\ny/6EW8/ZeO7C8O5C8Gppi75AxaIL2eiK++H8yNgUPuD8m8Hi3azTVEEelQKBgApI\nm6UE6y8lDJ1a0NyQGhuGSZn3MNcLgJUUC2nCPTDKHhqH6RbYc2wX0uhPl8fT6FAC\nurs3VGgr9COi0zxBeS7gdyrpA++D9WJA+jIxNlqkvPyEgL94oHahbeTvt1hHQYw6\ntjXaxU4Ot/5/zRAsL8iTsG96bB/yI3ZfXWdJC8TRAoGAE09F1stEofN5s9deFemB\nELAmhErjqjCpuHlwZGAqTGrl2eLNhAeVbvopW/A8SCb1L9ZPoKR9UgXUXc4j6W60\nfGbDEbNCZ2NM7qvZfZfvWxjo2sAOogSCsu6DUBjoSK38Ws8S6TzlsysbZ5MF+5uh\nsiMrm4zb8YQnBV799UMlcZY=\n-----END PRIVATE KEY-----\n",
      "client_email": "androidtest@personal-analytics-270310.iam.gserviceaccount.com",
      "client_id": "102147343302121240199",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/androidtest%40personal-analytics-270310.iam.gserviceaccount.com"
    }''');

    const _SCOPES = const [BigqueryApi.BigqueryScope];
    var httpClient = await clientViaServiceAccount(_credentials, _SCOPES);
    connection = new BigqueryApi(httpClient);
    isConnected = true;
  }

  @override
  deleteLastFrom(app.Table table, {verbose = false}) {
    // TODO: implement deleteLastFrom
    return null;
  }

  @override
  disconnect({verbose = false}) {
    // TODO: implement disconnect
    return null;
  }

  @override
  editLastFrom(app.Table table, Map<Property, dynamic> propertiesForm,
      {verbose = false}) {
    // TODO: implement editLastFrom
    return null;
  }

  @override
  getKeys({verbose = false}) {
    // TODO: implement getKeys
    return null;
  }

  @override
  getLastRow(app.Table table, {verbose = false}) {
    // TODO: implement getLastRow
    return null;
  }

  @override
  SvgPicture getLogo(Brightness brightness) =>
      SvgPicture.asset('assets/images/BigQuery.svg',
          height: 75, semanticsLabel: 'BigQuery Logo');

  @override
  Future<List<String>> getPkDistinctValues(app.Table table,
      {verbose = false, String pattern}) {
    // TODO: implement getPkDistinctValues
    return null;
  }

  @override
  Future<Set<Property>> getPropertiesFromTable(String table,
      {verbose = false}) async {
    var queryRequest = QueryRequest();
    queryRequest.query = "SELECT * FROM $datasetId.INFORMATION_SCHEMA.COLUMNS WHERE table_name = '$table'";
    queryRequest.useLegacySql = false;
    // TODO ? queryRequest.defaultDataset
    QueryResponse res = await connection.jobs.query(queryRequest, projectId);

    Set<Property> properties = Set();
    (res.toJson()["rows"] as List).forEach((r) {
      properties.add(Property(int.tryParse(r['f'][4]['v']), r['f'][3]['v'], r['f'][6]['v'].toString().toDataType(), null, r['f'][5]['v'] == 'YES' ? true : false));
    });

    return properties;
  }

  @override
  Future<List<String>> getTables({verbose = false}) async {
    var results =
        (await connection.tables.list(projectId, datasetId))
            .tables;
    return List.generate(results.length, (i) {
      return results[i].id.split(".").last;
    });
  }

  @override
  insertRowIntoTable(app.Table table, Map<Property, dynamic> propertiesForm,
      {verbose = false}) {
    // TODO: implement insertRowIntoTable
    return null;
  }

  @override
  Future<bool> ping({verbose = false}) async {
    return true;
  }

  @override
  pullDatabaseModel({verbose = false, getLastRows = true}) async {
    /// Get tables
    List<String> tablesNames = await getTables(verbose: verbose);

    /// For each table:
    Set<app.Table> tables = Set();
    for (var tName in tablesNames) {
      /// get properties...
      Set<Property> properties = await getPropertiesFromTable(tName);

      tables.add(app.Table(tName, properties, this));

      /// if first time loading DB model identify the "ORDER BY field", since Postgres has a date and timestamp type
      if (this.tables == null) {
        var orderByCandidates = properties.where((property) => [
          PrimitiveType.date,
          PrimitiveType.time,
          PrimitiveType.timestamp,
        ].contains(property.type.primitive));
        if (orderByCandidates.length == 1)
          tables.last.orderBy = orderByCandidates.first;
      }

      await tables.last.save(conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    this.tables = tables;

    /// get foreign and primary keys info
    await getKeys();
  }

  @override
  setConnectionParams(DbConnectionParams params, {verbose}) {
    // TODO: implement setConnectionParams
    return null;
  }
}
