// ignore_for_file: file_names

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// Hàm lấy tuyến đường dành riêng cho mapScreen
Future<List<LatLng>> getRouteForMapScreen(
  LatLng origin, 
  LatLng destination, 
  String routeType,
) async {
  String url;

  if (routeType == 'driving') {
    url = "http://router.project-osrm.org/route/v1/$routeType/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson";
  } else if (routeType == 'walking') {
    url = "https://api.mapbox.com/directions/v5/mapbox/walking/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?geometries=geojson&access_token=pk.eyJ1Ijoibmd1eWVua2hhaTIwMDMiLCJhIjoiY20zZWtnMHd0MGQ4aTJpcHhkNTNyb3h5YiJ9.OLZURwzqnNLb1bw-lS9Ixw";
  } else {
    throw Exception("Invalid route type: $routeType");
  }

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final geometry = data["routes"][0]["geometry"]["coordinates"] as List;

      // Chuyển đổi GeoJSON thành danh sách LatLng
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