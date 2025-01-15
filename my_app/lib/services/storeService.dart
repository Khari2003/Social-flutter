// ignore_for_file: file_names

import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'package:flutter_dotenv/flutter_dotenv.dart';

class StoreService {
  static const String ip = '192.168.1.5'; // Replace with your server's IP

  static Future<List<Map<String, dynamic>>> fetchStoresData() async {
    final response = await http.get(Uri.parse('http://$ip:4000/store/getall'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch stores data');
    }
  }
}
