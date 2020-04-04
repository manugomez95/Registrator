// TODO use?
abstract class PropertyType<T> {
  T value;
}

abstract class Database {
  String alias;
  Host host;
  Port port;
  DatabaseName dbName;
  Username username;
  Password password;
  // TODO useSSL?
}

abstract class DbParameter<T> {
  String title;
  T defaultValue;
}

class Alias extends DbParameter<String> {
  @override
  String get title => "Alias";
  @override
  String get defaultValue => "My data";
}

class Host extends DbParameter<String> {
  @override
  String get title => "Host";
  @override
  String get defaultValue => "192.168.X.XX";
}

class Port extends DbParameter<int> {
  @override
  String get title => "Port";
  @override
  int get defaultValue => 5432;
}

class DatabaseName extends DbParameter<String> {
  @override
  String get title => "DB name";
  @override
  String get defaultValue => "postgres";
}

class Username extends DbParameter<String> {
  @override
  String get title => "Username";
  @override
  String get defaultValue => "postgres";
}

class Password extends DbParameter<String> {
  @override
  String get title => "Password";
  @override
  String get defaultValue => "Ultra secret";
}

