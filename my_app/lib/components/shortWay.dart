// ignore_for_file: file_names

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// Hàm lấy tuyến đường từ OSRM API
Future<List<LatLng>> getShortestRoute(LatLng origin, LatLng destination) async {
  final String url =
      "http://router.project-osrm.org/route/v1/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson";
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final geometry = data["routes"][0]["geometry"]["coordinates"] as List;

      // Chuyển đổi dữ liệu GeoJSON thành danh sách LatLng
      return geometry
          .map((coord) => LatLng(coord[1] as double, coord[0] as double))
          .toList();
    } else {
      throw Exception("Error fetching route: ${response.reasonPhrase}");
    }
  } catch (e) {
    throw Exception("Error: $e");
  }
}
