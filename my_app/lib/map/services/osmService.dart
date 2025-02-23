// ignore_for_file: file_names

import 'dart:convert';
import 'package:http/http.dart' as http;

class OSMService {
  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.length < 2) return []; // Không tìm nếu quá ngắn

    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=5");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((place) => {
          "name": place["display_name"],
          "lat": place["lat"].toString(),
          "lon": place["lon"].toString()
        }).toList();
      }
    } catch (error) {
      // ignore: avoid_print
      print("Lỗi khi gọi API: $error");
    }
    return [];
  }
}
