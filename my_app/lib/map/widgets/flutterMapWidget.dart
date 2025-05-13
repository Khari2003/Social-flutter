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
  final Function(Map<String, dynamic>) onUserTap; // 👈 callback cho Marker user
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
    required this.onUserTap, // 👈 thêm constructor param
    this.searchedLocation,
    super.key,
  });

  @override
  _FlutterMapWidgetState createState() => _FlutterMapWidgetState();
}

class _FlutterMapWidgetState extends State<FlutterMapWidget> {
  late LatLng animatedLocation;
  Timer? movementTimer;
  List<Map<String, dynamic>> memberUsers = []; // 👈 lưu info user đầy đủ

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
        memberUsers = users.where((u) {
          final loc = u['location'];
          return loc is Map<String, dynamic> &&
              u['isAllowedLocation'] == true &&
              loc['lat'] != null && loc['lng'] != null;
        }).toList();
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
            widget.mapController.rotate(0);
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
                for (var user in memberUsers)
                  Marker(
                    point: LatLng(user['location']['lat'], user['location']['lng']),
                    width: 100.0,
                    height: 100.0,
                    child: GestureDetector(
                      onTap: () => widget.onUserTap(user), // 👈 callback
                      child: Column(
                        children: [
                          Text(
                            user['fullName'] ?? 'Vô danh',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          user['avatarUrl'] != null && user['avatarUrl'].toString().isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(user['avatarUrl']),
                                  radius: 20,
                                )
                              : const Icon(
                                  Icons.person_pin_circle,
                                  color: Colors.green,
                                  size: 40.0,
                                ),
                        ],
                      ),
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
