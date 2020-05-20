import 'dart:ui';
import 'package:bitacora/model/property.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';
import 'db_client.dart';
import 'package:bitacora/model/table.dart' as app;

extension BQString on String {
  DataType toDataType({String udtName, isArray: false}) {
    String arrayStr = isArray ? "[ ]" : "";
    if (this.contains("ARRAY")) {
      var type = this.replaceFirst("ARRAY", "").substring(1, this.length - 6);
      return type.toDataType(isArray: true);
    }
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
      default:
        throw UnsupportedError("$this not supported as a type");
    }
  }
}

// ignore: must_be_immutable
class BigQueryClient extends DbClient<BigqueryApi> {
  BigQueryClient._(DbConnectionParams params, List<PrimitiveType> orderByTypes,
      this.projectId, this.datasetId)
      : super(params, orderByTypes);

  factory BigQueryClient(
      DbConnectionParams params, String projectId, String datasetId) {
    List<PrimitiveType> orderByTypes = [
      PrimitiveType.integer,
      PrimitiveType.real,
    ];
    return BigQueryClient._(params, orderByTypes, projectId, datasetId);
  }

  final String projectId;
  final String datasetId;

  @override
  Future<Map<String, dynamic>> toMap() async {
    Map<String, dynamic> params = await super.toMap();
    params["brand"] = "bigquery";
    return params;
  }

  @override
  SvgPicture getLogo(Brightness brightness) =>
      SvgPicture.asset('assets/images/BigQuery.svg',
          height: 75, semanticsLabel: 'BigQuery Logo');

  @override
  Future<BigqueryApi> initConnection() async {
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
    return BigqueryApi(httpClient);
  }

  @override
  openConnection() {}

  @override
  closeConnection() {}

  @override
  Future<List<String>> getTables({verbose = false}) async {
    var results = (await connection.tables.list(projectId, datasetId)).tables;
    return List.generate(results.length, (i) {
      return results[i].id.split(".").last;
    });
  }

  @override
  Future<Set<Property>> getPropertiesFromTable(String table,
      {verbose = false}) async {
    List<dynamic> res = await execute(
        "SELECT * FROM $datasetId.INFORMATION_SCHEMA.COLUMNS WHERE table_name = '$table'");
    Set<Property> properties = Set();
    if (verbose) debugPrint(res.toString());
    res.forEach((r) {
      properties.add(Property(
          int.tryParse(r['f'][4]['v']),
          r['f'][3]['v'],
          r['f'][6]['v'].toString().toDataType(),
          null,
          r['f'][5]['v'] == 'YES' ? true : false));
    });
    return properties;
  }

  @override
  Future<bool> checkConnection() async {
    return await execute(
            "SELECT 1 FROM $datasetId.INFORMATION_SCHEMA.COLUMNS") !=
        null;
  }

  @override
  Future<List> queryLastRow(app.Table table, Property orderBy,
      {verbose: false}) async {
    String sql =
        "SELECT * FROM $datasetId.${dbStrFormat(table.name)} WHERE ${dbStrFormat(orderBy.name)} IS NOT NULL ORDER BY ${dbStrFormat(orderBy.name)} DESC LIMIT 1";
    if (verbose) debugPrint("getLastRow (${table.name}): $sql");
    List<dynamic> results = await execute(sql);
    return List.generate(
        (results[0]['f'] as List).length, (i) => results[0]['f'][i]['v']);
  }

  @override
  resToValue(res, DataType type, {fromArray: false}) {
    if (type.isArray && !fromArray && res != null) {
      var array = res as List;
      if (array.isEmpty) return null;
      return List.generate(array.length,
          (i) => resToValue(array[i]['v'], type, fromArray: true));
    }

    switch (type.primitive) {
      case PrimitiveType.date:
        return DateFormat("yyyy-MM-dd").parse(res);
      case PrimitiveType.timestamp:
        return DateTime.fromMicrosecondsSinceEpoch(
            (NumberFormat.scientificPattern().parse(res) * 1000000).toInt(),
            isUtc: true);
      default:
        return res;
    }
  }

  @override
  insertSQL(app.Table table, String properties, String values) {
    return "INSERT INTO $datasetId.${dbStrFormat(table.name)} ($properties) VALUES ($values)";
  }

  @override
  String editLastFromSQL(app.Table table) {
    List<Property> properties = table.properties.toList();

    String newValues =
        List.generate(properties.length, (i) => "${properties[i].name} = ?")
            .join(", ");
    return "UPDATE $datasetId.${table.name} SET $newValues ${whereLastValuesSQL(table)}";
  }

  Future<List<dynamic>> execute(String sql) async {
    var queryRequest = QueryRequest();
    // TODO ? queryRequest.defaultDataset
    queryRequest.query = sql;
    queryRequest.useLegacySql = false;
    return (await connection.jobs.query(queryRequest, projectId))
        .toJson()['rows'];
  }

  @override
  getKeys({verbose = false}) {}

  @override
  Future<List<String>> getPkDistinctValues(app.Table table,
      {verbose = false, String pattern}) {
    return null;
  }

  @override
  String fromValueToDbValue(value, DataType type,
      {bool fromArray = false, inWhere: false}) {
    /// IMPORTANT
    if (value == null || value.toString() == "")
      return 'null';
    else if (type.isArray && !fromArray) {
      if ((value as List).isEmpty) return null;
      String dbValue;
      dbValue =
          "[${(value as List).map((e) => fromValueToDbValue(e, type, fromArray: true)).join(", ")}]";
      if (inWhere) dbValue = "to_json_string($dbValue)";
      return dbValue;
    } else if (type.primitive == PrimitiveType.timestamp)
      return "'${value.toString()}'";
    else if (type.primitive == PrimitiveType.date)
      return "'${DateFormat("yyyy-MM-dd").format(value)}'";
    else if (type.primitive == PrimitiveType.text)
      return "'$value'";
    else
      return value;
  }

  @override
  String dbStrFormat(String str) {
    return str.toLowerCase() != str || str.contains(" ") ? '''"$str"''' : str;
  }

  @override
  Future<int> executeSQL(OpType opType, String command, List arguments) async {
    var i = -1;
    var sql = command.replaceAllMapped("?", (match) {
      i++;
      return arguments[i];
    });
    var queryRequest = QueryRequest();
    queryRequest.query = sql;
    queryRequest.useLegacySql = false;
    return int.tryParse((await connection.jobs.query(queryRequest, projectId)).toJson()['numDmlAffectedRows']);
  }

  @override
  String deleteLastFromSQL(app.Table table) =>
      "DELETE FROM $datasetId.${dbStrFormat(table.name)} ${whereLastValuesSQL(table)}";

  /// last values, IMPORTANT, when null there's no question mark so...
  String whereLastValuesSQL(app.Table table) =>
      "WHERE " +
      table.properties.map((Property p) {
        String fmtPName = dbStrFormat(p.name);
        if (!p.type.isArray)
          return "$fmtPName ${p.lastValue == null ? "is null" : "= ?"}";
        else {
          if (p.lastValue != null)
            return "to_json_string($fmtPName) = to_json_string(?)";
          else {
            return "ARRAY_LENGTH($fmtPName) = 0";
          }
        }
      }).join(" AND ");

  @override
  query(String command, List arguments) {
    // TODO: implement query
    throw UnimplementedError();
  }
}
