import 'dart:convert';

import 'package:http/http.dart' as http;

Future<List<String>> getTables() async {
  var client = new http.Client();
  final response = await client.get('http://192.168.1.14:3000/');
  if (response.statusCode == 200) {
    Map<String, dynamic> all = jsonDecode(response.body);
    print(all.toString());
    return (all['paths'] as Map<String, dynamic>).keys.toList().sublist(1).map((s) { return s.substring(1); } ).toList();
  } else {
    throw Exception('Unable to fetch tables from the REST API');
  }
}