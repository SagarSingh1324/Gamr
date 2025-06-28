import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String get _url => '${dotenv.env['BASE_URL'] ?? ''}/games';
  static String get _ttbUrl => '${dotenv.env['BASE_URL'] ?? ''}/game_time_to_beats';
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
            fields id,name,summary,cover.url,genres.name,game_modes;
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

  Future<List<Map<String, dynamic>>> fetchGameByName(String name) async {
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
            fields id, name, summary, cover.url,genres.name,game_modes;
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

  Future<List<dynamic>> fetchGameById(int id) async {
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
            fields id, name, summary, cover.url,genres.name,game_modes;
            where id = $id;
            limit 10;
            ''',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to load explore items: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchGameTimeToBeat(int gameId) async {
    final headers = {
      'Client-ID': _apiId,
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };
   
    try {
      final response = await http.post(
        Uri.parse(_ttbUrl),
        headers: headers,
        body: '''
            fields hastily, normally, completely;
            where game_id = $gameId;
            ''',
      );
     
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final timeToBeatData = data[0];
          return {
            'hastily': timeToBeatData['hastily'],
            'normally': timeToBeatData['normally'],
            'completely': timeToBeatData['completely'],
          };
        }
        return null;
      } else {
        throw Exception('Failed to load time to beat data: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }  
}