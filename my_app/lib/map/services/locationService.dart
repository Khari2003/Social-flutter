// ignore_for_file: file_names, deprecated_member_use

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  // Fetch the current location of the user
  static Future<LatLng?> fetchCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LatLng(21.0278, 105.8342);
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LatLng(21.0278, 105.8342);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LatLng(21.0278, 105.8342);
    }

    // Get the current position
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      return LatLng(21.0278, 105.8342);
    }
  }

  // Stream to track location updates every 5 seconds
  Stream<Position> get onLocationChanged {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    );
  }
}