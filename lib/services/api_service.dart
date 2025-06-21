import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {

  static String get _url => dotenv.env['BASE_URL'] ?? '';
  static String get _apiId => dotenv.env['API_ID'] ?? '';
  static String get _apiKey => dotenv.env['API_KEY'] ?? '';

  Future<List<Map<String, dynamic>>> fetchGameInstances(String genre, String sortBy) async {
    final headers = {
      'Client-ID': _apiId,
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: headers,
        body: '''
            fields id,name,summary,cover.url,genres.name;
            where genres.name = "$genre" & rating_count > 10;
            sort $sortBy desc;
            limit 20;
            ''',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load explore items: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchGameByName(String name) async{
    final headers = {
      'Client-ID': _apiId,
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: headers,
        body: '''
            fields id, name, summary, cover.url,genres.name; 
            search "$name"; 
            limit 10;
            ''',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load explore items: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

