// ignore_for_file: file_names

import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../helpers/shortWay.dart';

class RouteService {
  // Hàm lấy tuyến đường với tham số dành riêng cho mapScreen
  static Future<List<LatLng>> fetchRouteForMapScreen(
      LatLng currentLocation, LatLng destination, String routeType) async {
    // Xác định kiểu tuyến đường dựa trên routeType ('driving' hoặc 'walking')
    if (routeType != 'driving' && routeType != 'walking') {
      throw Exception("Invalid route type. Use 'driving' or 'walking'.");
    }

    // Sử dụng hàm getRoute từ shortWay.dart
    return await getRouteForMapScreen(currentLocation, destination, routeType);
  }
  
  static Future<void> updateRouteToStore({
    required LatLng currentLocation,
    required LatLng destination,
    required String routeType, 
    required MapController mapController,
    required Function(List<LatLng>) updateRouteCoordinates,
  }) async {
    // Sử dụng hàm fetchRouteForMapScreen

    final route = await RouteService.fetchRouteForMapScreen(
      currentLocation,
      destination,
      routeType, // Mặc định là driving, có thể thay đổi thành 'walking'
    );

    updateRouteCoordinates(route);

    // Tính toán trung tâm và mức zoom (giữ nguyên logic cũ)
    final double centerLat = (currentLocation.latitude + destination.latitude) / 2;
    final double centerLng = (currentLocation.longitude + destination.longitude) / 2;

    final double distance = Distance().as(
      LengthUnit.Kilometer,
      currentLocation,
      destination,
    );

    double zoomLevel;
    if (distance < 1) {
      zoomLevel = 16.0;
    } else if (distance < 5) {
      zoomLevel = 14.0;
    } else if (distance < 10) {
      zoomLevel = 12.0;
    } else {
      zoomLevel = 10.0;
    }
    
    mapController.move(LatLng(centerLat, centerLng), zoomLevel);
  }
}