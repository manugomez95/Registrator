import 'dart:ui';

import 'package:bitacora/model/property.dart';
import 'package:bitacora/utils/db_parameter.dart';
import 'package:flutter_svg/svg.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'db_client.dart';
import 'package:bitacora/model/table.dart' as app;

// ignore: must_be_immutable
class BigQueryClient extends DbClient<BigqueryApi> {
  BigQueryClient(DbConnectionParams params) : super(params);

  @override
  cancelLastInsertion(app.Table table, Map<Property, dynamic> propertiesForm,
      {verbose = false}) {
    // TODO: implement cancelLastInsertion
    return null;
  }

  @override
  connect({verbose = false}) {
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
    }'''
    );

    const _SCOPES = const [BigqueryApi.BigqueryScope];
    clientViaServiceAccount(_credentials, _SCOPES).then((httpClient) async {
      connection = new BigqueryApi(httpClient);
      print((await connection.tables.list("personal-analytics-270310", "my_data")).tables.first.id);
    });
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
      {verbose = false}) {
    // TODO: implement getPropertiesFromTable
    return null;
  }

  @override
  Future<List<String>> getTables({verbose = false}) {
    // TODO: implement getTables
    return null;
  }

  @override
  insertRowIntoTable(app.Table table, Map<Property, dynamic> propertiesForm,
      {verbose = false}) {
    // TODO: implement insertRowIntoTable
    return null;
  }

  @override
  Future<bool> ping({verbose = false}) {
    // TODO: implement ping
    return null;
  }

  @override
  pullDatabaseModel({verbose = false, getLastRows = true}) {
    // TODO: implement pullDatabaseModel
    return null;
  }

  @override
  setConnectionParams(DbConnectionParams params, {verbose}) {
    // TODO: implement setConnectionParams
    return null;
  }
}
