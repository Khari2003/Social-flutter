// ignore_for_file: file_names

import 'package:latlong2/latlong.dart';
import '../components/shortWay.dart';

class RouteService {
  static Future<List<LatLng>> fetchRoute(LatLng currentLocation, LatLng destination) async {
    return await getShortestRoute(currentLocation, destination);
  }
}
