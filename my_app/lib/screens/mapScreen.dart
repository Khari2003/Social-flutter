// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/locationService.dart';
import '../services/routeService.dart';
import '../services/storeService.dart';
import '../widgets/radiusSlider.dart';
import '../widgets/storeListWidget.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? currentLocation;
  List<Map<String, dynamic>> allStores = [];
  List<Map<String, dynamic>> filteredStores = [];
  List<LatLng> routeCoordinates = [];
  double radius = 1000.0;
  bool isStoreListVisible = true; // Trạng thái hiển thị danh sách

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    final location = await LocationService.fetchCurrentLocation();
    final storeData = await StoreService.fetchStoresData();
    setState(() {
      currentLocation = location;
      allStores = storeData;
      updateFilteredStores();
    });
  }

  void updateFilteredStores() {
    if (currentLocation != null) {
      setState(() {
        filteredStores = allStores.where((store) {
          final coordinates = store['coordinates'];
          final storeLocation = LatLng(coordinates['lat'], coordinates['lng']);
          final distance = Distance().as(
            LengthUnit.Meter,
            currentLocation!,
            storeLocation,
          );
          return distance <= radius;
        }).toList();
      });
    }
  }

  Future<void> updateRouteToStore(LatLng destination) async {
    if (currentLocation != null) {
      final route = await RouteService.fetchRoute(currentLocation!, destination);
      setState(() {
        routeCoordinates = route;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchInitialData,
          ),
        ],
      ),
      body: currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: currentLocation!,
                      initialZoom: 14.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routeCoordinates,
                            strokeWidth: 4.0,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: radius, end: radius),
                        duration: const Duration(milliseconds: 300),
                        builder: (context, value, child) {
                          return CircleLayer(
                            circles: [
                              CircleMarker(
                                point: currentLocation!,
                                // ignore: deprecated_member_use
                                color: Colors.blue.withOpacity(0.3),
                                borderStrokeWidth: 1.0,
                                borderColor: Colors.blue,
                                useRadiusInMeter: true,
                                radius: value, // Sử dụng giá trị radius từ animation
                              ),
                            ],
                          );
                        },
                      ),
                      MarkerLayer(
                        markers: _buildMarkers(),
                      ),
                    ],
                  ),
                ),
                RadiusSlider(
                  radius: radius,
                  onRadiusChanged: (value) {
                    setState(() {
                      radius = value;
                      updateFilteredStores();
                      // Ẩn danh sách khi vuốt xuống, hiện khi vuốt lên
                      if (value > 3000) {
                        isStoreListVisible = false; // Ẩn danh sách
                      } else {
                        isStoreListVisible = true; // Hiện danh sách
                      }
                    });
                  },
                ),
                StoreListWidget(
                  stores: filteredStores,
                  onSelectStore: (LatLng destination) {
                    updateRouteToStore(destination);
                  },
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchInitialData,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];
    if (currentLocation != null) {
      markers.add(Marker(
        width: 80.0,
        height: 80.0,
        point: currentLocation!,
        child: const Icon(Icons.my_location, color: Colors.green, size: 40.0),
      ));
    }
    markers.addAll(filteredStores.map((store) {
      final coordinates = store['coordinates'];
      return Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(coordinates['lat'], coordinates['lng']),
        child: GestureDetector(
          onTap: () {
            updateRouteToStore(LatLng(coordinates['lat'], coordinates['lng']));
          },
          child: const Icon(Icons.location_on, color: Colors.red, size: 40.0),
        ),
      );
    }).toList());
    return markers;
  }
}
