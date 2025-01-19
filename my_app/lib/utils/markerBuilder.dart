// ignore_for_file: file_names

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';

List<Marker> buildMarkers({
  required LatLng? currentLocation,
  required bool isNavigating,
  required double? userHeading,
  required List<Map<String, dynamic>> filteredStores,
  required Map<String, dynamic>? navigatingStore,
  required void Function(Map<String, dynamic>) onSelectStore,
}) {
  List<Marker> markers = [];

  if (currentLocation != null) {
    markers.add(Marker(
      width: 80.0,
      height: 80.0,
      point: currentLocation,
      child: isNavigating && userHeading != null
          ? TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: userHeading, end: userHeading),
              duration: const Duration(milliseconds: 300),
              builder: (context, rotation, child) {
                return Transform.rotate(
                  angle: rotation,
                  child: SvgPicture.asset(
                    'assets/location-arrow.svg',
                    width: 40.0,
                    height: 40.0,
                  ),
                );
              },
            )
          : const Icon(
              Icons.my_location,
              color: Colors.green,
              size: 40.0,
            ),
    ));
  }

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

  if (!isNavigating) {
    markers.addAll(filteredStores.map((store) {
      final coordinates = store['coordinates'];
      return Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(coordinates['lat'], coordinates['lng']),
        child: GestureDetector(
          onTap: () => onSelectStore(store),
          child: const Icon(Icons.location_on, color: Colors.red, size: 40.0),
        ),
      );
    }).toList());
  }

  return markers;
}
