import 'package:postgres/postgres.dart';
import 'package:registrator/model/databaseModel.dart';
import 'package:registrator/model/property.dart';
import 'package:registrator/model/table.dart' as my;

// TODO complete and add short name field and flutter input type
var postgresTypes = {
  "timestamp without time zone": PostgreSQLDataType.timestampWithoutTimezone,
  "timestamp with time zone": PostgreSQLDataType.timestampWithTimezone,
  "character varying": PostgreSQLDataType.text,
  "integer": PostgreSQLDataType.integer,
  "smallint": PostgreSQLDataType.smallInteger,
  "boolean": PostgreSQLDataType.boolean,
  "real": PostgreSQLDataType.real,
  "date": PostgreSQLDataType.date,
  "oid": PostgreSQLDataType.uuid
};

class PostgresClient {

  var connection;

  /// Private constructor
  PostgresClient._create() {
    print("_create() (private constructor)");

    // Do most of your initialization here, that's what a constructor is for
    //...
  }

  /// Public factory
  static Future<PostgresClient> create() async {
    print("create() (public factory)");

    // Call the private constructor
    var component = PostgresClient._create();
    component.connection = new PostgreSQLConnection("192.168.1.14", 5432, "my_data",
        username: "postgres", password: r"!$36<BD5vuP7");
    await component.connection.open();
    // Do initialization that requires async
    //await component._complexAsyncInit();

    // Return the fully initialized object
    return component;
  }

  static Future<List<String>> getTables() async {
    var connection = new PostgreSQLConnection("192.168.1.14", 5432, "my_data",
        username: "postgres", password: r"!$36<BD5vuP7");
    await connection.open();

    List<List<dynamic>> results = await connection.query(
        r"SELECT table_name "
        r"FROM information_schema.tables "
        r"WHERE table_type = 'BASE TABLE' "
        r"AND table_schema = @tableSchema",
        substitutionValues: {"tableSchema": "public"});

    connection.close();

    return results.expand((i) => i).toList().cast<String>();
  }

  static Future<List<Property>> getPropertiesFromTable(PostgreSQLConnection connection, String table) async {
    List<List<dynamic>> results = await connection.query(
        r"SELECT column_name, data_type FROM information_schema.columns "
        r"WHERE table_schema = @tableSchema AND table_name   = @tableName",
        substitutionValues: {"tableSchema": "public", "tableName": table});

    var r = results.map((res) { return Property(res[0], postgresTypes[res[1]]); }).toList().cast<Property>();

    return r;
  }

  static Future<DatabaseModel> getDatabaseModel(dbName) async {
    var connection = new PostgreSQLConnection("192.168.1.14", 5432, dbName,
        username: "postgres", password: r"!$36<BD5vuP7");
    await connection.open();

    print("Conectando con postgres");

    List<List<dynamic>> tablesResponse = await connection.query(
        r"SELECT table_name "
        r"FROM information_schema.tables "
        r"WHERE table_type = 'BASE TABLE' "
        r"AND table_schema = @tableSchema",
        substitutionValues: {"tableSchema": "public"});

    List<String> tablesNames = tablesResponse.expand((i) => i).toList().cast<String>();

    print(tablesNames);

    List<my.Table> tables = [];
    for (var tName in tablesNames) {
      List<Property> properties = await getPropertiesFromTable(connection, tName);
      tables.add(my.Table(tName, properties));
    }

    print(tables);

    connection.close();

    return DatabaseModel(dbName, tables);
  }
}
