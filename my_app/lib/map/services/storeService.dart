// ignore_for_file: file_names

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StoreService {

  static Future<List<Map<String, dynamic>>> fetchStoresData() async {
    final response = await http.get(Uri.parse('https://server-holy-breeze-594.fly.dev/store/getall'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch stores data');
    }
  }
  
}
