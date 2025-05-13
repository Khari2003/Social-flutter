import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

List<Marker> buildMarkers({
  required LatLng? currentLocation,
  required bool isNavigating,
  required double? userHeading,
  required Map<String, dynamic>? navigatingStore,
  required List<Map<String, dynamic>> filteredStores,
  required void Function(Map<String, dynamic>) onStoreTap,
  required double mapRotation,
  String? avatarUrl, // Thêm tham số avatarUrl
}) {
  List<Marker> markers = [];

  // Marker cho vị trí hiện tại của người dùng
  if (currentLocation != null) {
    markers.add(Marker(
      width: 80.0,
      height: 80.0,
      point: currentLocation,
      child: isNavigating && userHeading != null
          ? Transform.rotate(
              angle: (mapRotation) * (3.14159265359 / 180),
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(avatarUrl),
                    )
                  : const Icon(
                      Icons.person_pin_circle,
                      color: Colors.blue,
                      size: 40.0,
                    ),
            )
          : Transform.rotate(
              angle: 3.14159265359 / 180,
              child: const Icon(
                Icons.my_location,
                color: Colors.green,
                size: 40.0,
              ),
            ),
    ));
  }

  // Marker cho cửa hàng đang điều hướng
  if (isNavigating && navigatingStore != null) {
    markers.add(Marker(
      width: 80.0,
      height: 80.0,
      point: LatLng(
        navigatingStore['coordinates']['lat'],
        navigatingStore['coordinates']['lng'],
      ),
      child: const Icon(Icons.location_on, color: Colors.red, size: 40.0),
    ));
  }

  // Marker cho các cửa hàng (chỉ khi không điều hướng)
  if (!isNavigating) {
    markers.addAll(filteredStores.map((store) {
      final coordinates = store['coordinates'];
      return Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(coordinates['lat'], coordinates['lng']),
        child: GestureDetector(
          onTap: () => onStoreTap(store),
          child: const Icon(Icons.location_on, color: Colors.red, size: 40.0),
        ),
      );
    }).toList());
  }

  return markers;
}