import 'package:postgres/postgres.dart';

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

  static Future<List<String>> getPropertiesFromTable(String table) async {
    var connection = new PostgreSQLConnection("192.168.1.14", 5432, "my_data",
        username: "postgres", password: r"!$36<BD5vuP7");
    await connection.open();

    List<List<dynamic>> results = await connection.query(
        r"SELECT * FROM information_schema.columns "
        r"WHERE table_schema = @tableSchema AND table_name   = @tableName",
        substitutionValues: {"tableSchema": "public", "tableName": table});

    connection.close();

    return results.map((e) { return e[3]; }).toList().cast<String>();
  }
}
