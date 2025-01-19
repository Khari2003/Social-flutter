// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends StatelessWidget {
  final MapController mapController;
  final LatLng initialLocation; 
  final List<Polyline> polylines;
  final bool showRadius;
  final double radius;
  final List<Marker> markers;

  const MapWidget({
    super.key,
    required this.mapController,
    required this.initialLocation,
    required this.polylines,
    required this.showRadius,
    required this.radius,
    required this.markers,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialLocation,
        initialZoom: 14.0,
      ),
      children: [
        // Tile layer for the map background
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        // Polyline layer for routes
        if (polylines.isNotEmpty)
          PolylineLayer(
            polylines: polylines,
          ),
        // Circle layer for search radius
        if (showRadius)
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: radius, end: radius),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return CircleLayer(
                circles: [
                  CircleMarker(
                    point: initialLocation,
                    // ignore: deprecated_member_use
                    color: Colors.blue.withOpacity(0.3),
                    borderStrokeWidth: 1.0,
                    borderColor: Colors.blue,
                    useRadiusInMeter: true,
                    radius: value,
                  ),
                ],
              );
            },
          ),
        // Marker layer for points of interest
        if (markers.isNotEmpty)
          MarkerLayer(
            markers: markers,
          ),
      ],
    );
  }
}