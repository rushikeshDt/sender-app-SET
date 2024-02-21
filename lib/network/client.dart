import 'package:http/http.dart' as http;
import 'dart:convert';

class Client {
  static const String baseUrl =
      'https://firestore-api-set-2.glitch.me'; // Replace with your server base URL

  static Client? _instance;

  static Client getInstance() {
    _instance ??= Client();
    return _instance!;
  }

  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    print("post fired :${endpoint} $data");
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(data),
    );

    return _handleResponse(response);
  }

//get method has issue with body

  // Future<Map<String, dynamic>> get(String endpoint, dynamic data) async {
  //   // var request = http.Request(
  //   //     'GET',
  //   //     Uri.parse(
  //   //       '$baseUrl/$endpoint',
  //   //     ));
  //   // request.body = data.toString();
  //   Uri uri = Uri.parse(
  //     '$baseUrl/$endpoint',
  //   ).replace(queryParameters: data);

  //   final params = Uri.encodeQueryComponent(data.toString());

  //   final uriWithParams = Uri.parse('$uri?json=$params');

  //   final response = await http.get(uriWithParams, headers: <String, String>{
  //     'Content-Type': 'application/json; charset=UTF-8',
  //   });
  //   print("get fired :${endpoint} $response");

  //   // final response = await request.send();

  //   return _handleResponse(response);
  // }

  Map<String, dynamic> _handleResponse(dynamic response) {
    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON
      print("response received ${response.body}");

      return jsonDecode(response.body);
    } else {
      // If the server did not return a 200 OK response, throw an exception.
      throw Exception(
          'Failed to load data. Status code: ${response.statusCode}');
    }
  }
}
