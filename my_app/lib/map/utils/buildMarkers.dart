// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_svg/flutter_svg.dart';

List<Marker> buildMarkers({
  required LatLng? currentLocation,
  required bool isNavigating,
  required double? userHeading,
  required Map<String, dynamic>? navigatingStore,
  required List<Map<String, dynamic>> filteredStores,
  required void Function(Map<String, dynamic>) onStoreTap,
  required double mapRotation,
}) {
  List<Marker> markers = [];

  // Marker for user's current location
  if (currentLocation != null) {
    markers.add(Marker(
      width: 80.0,
      height: 80.0,
      point: currentLocation,
      child: isNavigating && userHeading != null
          ? Transform.rotate(
              angle: (mapRotation) * (3.14159265359 / 180),
              child: SvgPicture.asset(
                'assets/location-arrow.svg', // Custom SVG for navigation
                width: 40.0,
                height: 40.0,
              ),
            )
          : Transform.rotate(
              angle: 3.14159265359 / 180,
              child: const Icon(
                Icons.my_location,
                color: Colors.green,
                size: 40.0,
              ),
            )
    ));
  }

  // Marker for the navigating store
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

  // Markers for all stores (only when not navigating)
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
