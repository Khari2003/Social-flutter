// ignore_for_file: file_names

import 'dart:convert';
import 'package:http/http.dart' as http;

class StoreService {

  static Future<List<Map<String, dynamic>>> fetchStoresData() async {
    final response = await http.get(Uri.parse('http://172.19.200.122:4000/store/getall'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch stores data');
    }
  }
  
}
