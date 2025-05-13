// ignore_for_file: file_names, library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:my_app/services/auth/authService.dart';
import 'dart:async';
import '../utils/buildMarkers.dart';
import '../utils/dashPolyline.dart';

class FlutterMapWidget extends StatefulWidget {
  final MapController mapController;
  final LatLng currentLocation;
  final double radius;
  final bool isNavigating;
  final double? userHeading;
  final Map<String, dynamic>? navigatingStore;
  final List<Map<String, dynamic>> filteredStores;
  final List<LatLng> routeCoordinates;
  final String routeType;
  final Function(Map<String, dynamic>) onStoreTap;
  final LatLng? searchedLocation;

  const FlutterMapWidget({
    required this.mapController,
    required this.currentLocation,
    required this.radius,
    required this.isNavigating,
    this.userHeading,
    this.navigatingStore,
    required this.filteredStores,
    required this.routeCoordinates,
    required this.routeType,
    required this.onStoreTap,
    this.searchedLocation,
    super.key,
  });

  @override
  _FlutterMapWidgetState createState() => _FlutterMapWidgetState();
}

class _FlutterMapWidgetState extends State<FlutterMapWidget> {
  late LatLng animatedLocation;
  Timer? movementTimer;
  List<LatLng> memberLocations = [];

  @override
  void initState() {
    super.initState();
    animatedLocation = widget.currentLocation;
    _startSmoothMovement();
    _fetchMemberLocations();
  }

  @override
  void didUpdateWidget(covariant FlutterMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLocation != widget.currentLocation) {
      _startSmoothMovement();
    }
  }

  Future<void> _fetchMemberLocations() async {
    try {
      List<Map<String, dynamic>> users = await Authservice().getAllUsers();
      
      setState(() {
        memberLocations = users.map((u) {
          // Kiểm tra kỹ giá trị của location
          var location = u['location'];
          if (location is Map<String, dynamic> && u['isAllowedLocation'] == true) {
            return LatLng(location['lat'] as double, location['lng'] as double);
          }
          return null;
        }).whereType<LatLng>().toList();
      });
    } catch (e) {
      print("Error fetching user locations: $e");
    }
  }

  void _startSmoothMovement() {
    movementTimer?.cancel();
    const duration = Duration(milliseconds: 100);
    movementTimer = Timer.periodic(duration, (timer) {
      setState(() {
        animatedLocation = LatLng(
          (animatedLocation.latitude + widget.currentLocation.latitude) / 2,
          (animatedLocation.longitude + widget.currentLocation.longitude) / 2,
        );
      });
      if ((animatedLocation.latitude - widget.currentLocation.latitude).abs() < 0.0001 &&
          (animatedLocation.longitude - widget.currentLocation.longitude).abs() < 0.0001) {
        timer.cancel();
        setState(() {
          animatedLocation = widget.currentLocation;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        final heading = snapshot.data?.heading ?? 0;
        
        if (widget.isNavigating) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.mapController.rotate(-heading);
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.mapController.rotate(0); // Giữ bản đồ thẳng khi không điều hướng
          });
        }

        return FlutterMap(
          mapController: widget.mapController,
          options: MapOptions(
            initialCenter: animatedLocation,
            initialZoom: 14.0,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            ),
            PolylineLayer(
              polylines: widget.routeType == 'walking'
                  ? generateDashedPolyline(widget.routeCoordinates)
                  : [
                      Polyline(
                        points: widget.routeCoordinates,
                        strokeWidth: 5.0,
                        // ignore: deprecated_member_use
                        color: Colors.blue.withOpacity(0.75),
                      ),
                    ],
            ),
            MarkerLayer(
              markers: [
                ...buildMarkers(
                  currentLocation: animatedLocation,
                  isNavigating: widget.isNavigating,
                  userHeading: widget.userHeading,
                  navigatingStore: widget.navigatingStore,
                  filteredStores: widget.filteredStores,
                  onStoreTap: widget.onStoreTap,
                  mapRotation: heading,
                ),
                for (var loc in memberLocations)
                  Marker(
                    point: loc,
                    width: 50.0,
                    height: 50.0,
                    child: const Icon(
                      Icons.person_pin_circle,
                      color: Colors.green,
                      size: 40.0,
                    ),
                  ),
                if (widget.searchedLocation != null)
                  Marker(
                    width: 80.0,
                    height: 80.0,
                    point: widget.searchedLocation!,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.blue,
                      size: 40.0,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    movementTimer?.cancel();
    super.dispose();
  }
}