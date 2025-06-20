import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/game_instance.dart';

class ApiService {

  static String get _url => dotenv.env['BASE_URL'] ?? '';
  static String get _apiId => dotenv.env['API_ID'] ?? '';
  static String get _apiKey => dotenv.env['API_KEY'] ?? '';

  // Option 1: Return raw JSON (matches current ViewModel expectation)
  Future<List<Map<String, dynamic>>> fetchGameInstances() async {
    final headers = {
      'Client-ID': _apiId,
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'text/plain',
    };

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: headers,
        body: '''
            fields id, name, summary;
            where rating > 90 & first_release_date > 1577836800;
            sort rating desc;
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

  // Option 2: Return parsed objects (alternative approach)
  Future<List<GameInstance>> fetchGameInstancesParsed() async {
    final headers = {
      'Client-ID': _apiId,
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'text/plain',
    };

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: headers,
        body: '''
            fields id, name;
            where rating > 90 & first_release_date > 1577836800;
            sort rating desc;
            limit 20;
            ''',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .cast<Map<String, dynamic>>()
            .map((json) => GameInstance.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load explore items: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

