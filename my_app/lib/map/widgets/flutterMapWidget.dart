import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:my_app/services/auth/authService.dart';
import 'dart:async';
import '../utils/buildMarkers.dart';
import '../utils/dashPolyline.dart';
import 'package:provider/provider.dart';

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
  final Function(Map<String, dynamic>) onUserTap;
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
    required this.onUserTap,
    this.searchedLocation,
    super.key,
  });

  @override
  _FlutterMapWidgetState createState() => _FlutterMapWidgetState();
}

class _FlutterMapWidgetState extends State<FlutterMapWidget> {
  List<Map<String, dynamic>> memberUsers = [];
  double _smoothedHeading = 0;
  final List<double> _headingBuffer = [];
  final int _bufferSize = 5;
  String? _currentUserAvatarUrl;

  @override
  void initState() {
    super.initState();
    _fetchMemberLocations();
    _fetchCurrentUserAvatar();
  }

  Future<void> _fetchCurrentUserAvatar() async {
    try {
      final authService = Provider.of<Authservice>(context, listen: false);
      final currentUserId = authService.currentUser?.uid;
      if (currentUserId != null) {
        final user = await authService.getUserById(currentUserId);
        setState(() {
          _currentUserAvatarUrl = user?.avatarUrl;
        });
      }
    } catch (e) {
      debugPrint("Error fetching current user avatar: $e");
    }
  }

  Future<void> _fetchMemberLocations() async {
    try {
      final authService = Provider.of<Authservice>(context, listen: false);
      final currentUserId = authService.currentUser?.uid;
      List<Map<String, dynamic>> users = await authService.getAllUsers();
      setState(() {
        memberUsers = users.where((u) {
          final loc = u['location'];
          return loc is Map<String, dynamic> &&
              u['isAllowedLocation'] == true &&
              loc['lat'] != null &&
              loc['lng'] != null &&
              u['uid'] != currentUserId; // Lọc bỏ người dùng hiện tại
        }).toList();
      });
    } catch (e) {
      debugPrint("Error fetching user locations: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _headingBuffer.add(snapshot.data!.heading ?? 0);
          if (_headingBuffer.length > _bufferSize) {
            _headingBuffer.removeAt(0);
          }
          _smoothedHeading = _headingBuffer.reduce((a, b) => a + b) / _headingBuffer.length;
        }

        if (widget.isNavigating) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.mapController.rotate(-_smoothedHeading);
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.mapController.rotate(0);
          });
        }

        return FlutterMap(
          mapController: widget.mapController,
          options: MapOptions(
            initialCenter: widget.currentLocation,
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
                  currentLocation: widget.currentLocation,
                  isNavigating: widget.isNavigating,
                  userHeading: widget.userHeading,
                  navigatingStore: widget.navigatingStore,
                  filteredStores: widget.filteredStores,
                  onStoreTap: widget.onStoreTap,
                  mapRotation: _smoothedHeading,
                  avatarUrl: _currentUserAvatarUrl, // Truyền avatarUrl
                ),
                for (var user in memberUsers)
                  Marker(
                    point: LatLng(user['location']['lat'], user['location']['lng']),
                    width: 100.0,
                    height: 100.0,
                    child: GestureDetector(
                      onTap: () => widget.onUserTap(user),
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
    super.dispose();
  }
}