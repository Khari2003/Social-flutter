// ignore_for_file: file_names
import 'dart:convert';
import 'package:http/http.dart' as http;

class StoreService {
  static Future<List<Map<String, dynamic>>> fetchStoresData() async {
    final response = await http.get(
      Uri.parse('https://server-morning-forest-197.fly.dev/api/stores'),
    );
    
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch stores data');
    }
  }
}