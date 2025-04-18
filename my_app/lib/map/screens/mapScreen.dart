// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/locationService.dart';
import '../services/routeService.dart';
import '../services/storeService.dart';
import '../widgets/radiusSlider.dart';
import '../widgets/storeListWidget.dart';
import '../widgets/StoreDetailWidget.dart';
import '../widgets/flutterMapWidget.dart';
import '../widgets/searchStoreWidget.dart';

class MapScreen extends StatefulWidget {
  final String? selectedGroupId;

  const MapScreen({Key? key, this.selectedGroupId}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin,AutomaticKeepAliveClientMixin {
  LatLng? currentLocation;
  List<Map<String, dynamic>> allStores = [];
  List<Map<String, dynamic>> traffic = [];
  List<Map<String, dynamic>> filteredStores = [];
  List<LatLng> routeCoordinates = [];
  double radius = 1000.0;
  bool isStoreListVisible = false;
  bool shouldDrawRoute = false;
  Map<String, dynamic>? selectedStore;
  final MapController _mapController = MapController();
  bool isNavigating = false; // Xác định chế độ điều hướng
  double? userHeading; // Hướng của người dùng
  Map<String, dynamic>? navigatingStore;
  String routeType = 'driving';
  AnimationController? _animationController;
  LatLng? searchedLocation;
  bool get wantKeepAlive => true;
  @override
  @override
  void initState() {
    super.initState();
    fetchInitialData();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> fetchInitialData() async {
    final results = await Future.wait([
      LocationService.fetchCurrentLocation(),
      StoreService.fetchStoresData(),
    ]);

    setState(() {
      currentLocation = results[0] as LatLng;
      allStores = results[1] as List<Map<String, dynamic>>;
      updateFilteredStores();
    });
  }

  void updateFilteredStores() {
    if (currentLocation == null) return;

    final List<Map<String, dynamic>> updatedStores = allStores.where((store) {
      final coordinates = store['coordinates'];
      final storeLocation = LatLng(coordinates['lat'], coordinates['lng']);
      return Distance().as(LengthUnit.Meter, currentLocation!, storeLocation) <= radius;
    }).toList();

    setState(() {
      filteredStores = updatedStores;
    });
  }

  void _startNavigation() {
    if (currentLocation != null) {
      _mapController.move(currentLocation!, 20.0); // Zoom vào vị trí người dùng
      _trackUserLocationAndDirection(); // Theo dõi vị trí và hướng của người dùng
    }
  }

  void _trackUserLocationAndDirection() {
    final locationService = LocationService();
    LatLng? previousLocation = currentLocation;

    locationService.onLocationChanged.listen((position) async {
      final newLocation = LatLng(position.latitude, position.longitude);
      _animateMapToLocation(newLocation);

      if (previousLocation != null) {
        // Tính toán khoảng cách giữa vị trí cũ và mới
        final distance = Distance().as(LengthUnit.Meter, previousLocation!, newLocation);

        // Nếu khoảng cách quá lớn, sử dụng nội suy để di chuyển mượt mà
        if (distance > 1) {
          final steps = 10; // Số bước di chuyển
          final latStep = (newLocation.latitude - previousLocation!.latitude) / steps;
          final lngStep = (newLocation.longitude - previousLocation!.longitude) / steps;

          for (int i = 0; i < steps; i++) {
            await Future.delayed(const Duration(milliseconds: 50)); // Độ trễ giữa các bước
            setState(() {
              currentLocation = LatLng(
                previousLocation!.latitude + latStep * i,
                previousLocation!.longitude + lngStep * i,
              );
            });
          }
        }
      }

      setState(() {
        currentLocation = newLocation; // Cập nhật vị trí cuối cùng
        userHeading = position.heading; // Cập nhật hướng
      });

      if (isNavigating) {
        _mapController.move(newLocation, 20.0); // Di chuyển bản đồ
        _checkIfOnRoute(newLocation); // Kiểm tra vị trí trên tuyến đường
        _checkIfArrived(newLocation); // Thêm kiểm tra đến nơi
      }

      previousLocation = newLocation;
    });
  }

  void _animateMapToLocation(LatLng newLocation) {
    if (_animationController == null) return;

    final latTween = Tween<double>(begin: currentLocation?.latitude, end: newLocation.latitude);
    final lngTween = Tween<double>(begin: currentLocation?.longitude, end: newLocation.longitude);

    final animation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );

    animation.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        _mapController.move(newLocation, 20.0) as double
      );
    });

    _animationController!.forward(from: 0.0);
  }

  Future<void> _checkIfOnRoute(LatLng userLocation) async {
    if (routeCoordinates.isEmpty) return;

    final nextPoint = routeCoordinates.first;
    final distanceToNextPoint = Distance().as(LengthUnit.Meter, userLocation, nextPoint);

    if (distanceToNextPoint < 5) { 
      setState(() {
        routeCoordinates.removeAt(0);
      });
    } else if (distanceToNextPoint > 10) { 
      final newRoute = await RouteService.fetchRouteForMapScreen(
        userLocation,
        routeCoordinates.last,
        routeType,
      );
      setState(() {
        routeCoordinates = newRoute;
      });
    }
  }

  void _resetToInitialState() {
    setState(() {
      isNavigating = false;
      routeCoordinates.clear(); // Xóa lộ trình
      userHeading = null; // Xóa hướng người dùng
      selectedStore = null; // Bỏ chọn cửa hàng
      searchedLocation = null; // Xóa địa chỉ tìm kiếm
      radius = 1000.0; // Reset bán kính
      updateFilteredStores();
    });
  }

  void _checkIfArrived(LatLng userLocation) {
      if (routeCoordinates.isNotEmpty) {
          final destination = routeCoordinates.last;
          final distanceToDestination = Distance().as(LengthUnit.Meter, userLocation, destination);

          if (distanceToDestination < 5) { // Ngưỡng 5m
              setState(() {
                  isNavigating = false;
                  routeCoordinates.clear();
              });

              // Hiển thị thông báo đã đến nơi
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                      title: const Text("Đã đến nơi"),
                      content: const Text("Bạn đã đến điểm đến!"),
                      actions: [
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text("OK"),
                          ),
                      ],
                  ),
              );
          }
      }
  }

  Future<void> updateRouteToStore(LatLng destination) async {
    if (currentLocation != null) {
      await RouteService.updateRouteToStore(
        currentLocation: currentLocation!,
        destination: destination,
        routeType: routeType,
        mapController: _mapController,
        updateRouteCoordinates: (route) {
          setState(() {
            routeCoordinates = route;
            navigatingStore = selectedStore;
            selectedStore = null;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          setState(() {
            selectedStore = null; // Ẩn StoreDetail khi nhấn ra ngoài
          });
        },
        child: currentLocation == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  FlutterMapWidget(
                    mapController: _mapController,
                    currentLocation: currentLocation!,
                    radius: radius,
                    isNavigating: isNavigating,
                    userHeading: userHeading,
                    navigatingStore: navigatingStore,
                    filteredStores: filteredStores,
                    routeCoordinates: routeCoordinates,
                    routeType: routeType,
                    onStoreTap: (store) {
                      setState(() {
                        selectedStore = store;
                      });
                    },
                    searchedLocation: searchedLocation,
                    groupId: widget.selectedGroupId ?? "defaultGroupId",
                  ),  
                  // Nút tìm kiếm địa chỉ
                  Positioned(
                    top: 16.0,
                    right: 16.0,
                    child: FloatingActionButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchPlaces(),
                          ),
                        );

                        if (result != null && result is Map<String, String>) {
                          final double lat = double.parse(result['lat']!);
                          final double lon = double.parse(result['lon']!);
                          LatLng newLocation = LatLng(lat, lon);

                          setState(() {
                            searchedLocation = newLocation; // Lưu vị trí tìm kiếm
                            _mapController.move(newLocation, 16.0);
                          });

                          // Tạo tuyến đường đến vị trí tìm kiếm
                          if (currentLocation != null) {
                            await updateRouteToStore(newLocation);
                          }
                        }
                      },
                      child: const Icon(Icons.search),
                    ),
                  ),
                  Positioned(
                    bottom: 150.0,
                    right: 33.0,
                    child: Column(
                      children: [
                        FloatingActionButton(
                          onPressed: () async {
                            setState(() {
                              routeType = routeType == 'driving' ? 'walking' : 'driving';
                            });

                            // Cập nhật lại tuyến đường
                            if (currentLocation != null && routeCoordinates.isNotEmpty) {
                              final newRoute = await RouteService.fetchRouteForMapScreen(
                                currentLocation!,
                                routeCoordinates.last,
                                routeType,
                              );
                              setState(() {
                                routeCoordinates = newRoute;
                              });
                            }
                          },
                          heroTag: 'toggle_route_type',
                          backgroundColor: routeType == 'driving' ? Colors.blue : Colors.green,
                          child: Icon(
                            routeType == 'driving' ? Icons.directions_car : Icons.directions_walk,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        // Nút "Bắt đầu đi"
                        if (routeCoordinates.isNotEmpty && !isNavigating)
                          FloatingActionButton(
                            onPressed: () {
                              setState(() {
                                isNavigating = true; // Kích hoạt chế độ điều hướng
                              });
                              _startNavigation(); // Bắt đầu điều hướng
                            },
                            heroTag: 'start_navigation',
                            child: const Icon(
                              Icons.play_arrow,
                            ),
                          ),
                        const SizedBox(height: 16.0),

                        // Nút "Kết thúc"
                        if (isNavigating)
                          FloatingActionButton(
                            onPressed: _resetToInitialState,
                            heroTag: 'end_navigation',
                            backgroundColor: Colors.red,
                            child: const Icon(Icons.stop),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 16.0,
                    left: 16.0,
                    right: 16.0,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Card(
                          margin: const EdgeInsets.all(8.0),
                          elevation: 4,
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 300.0),
                            padding: const EdgeInsets.all(8.0),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (!isNavigating)
                                    RadiusSlider(
                                      radius: radius,
                                      onRadiusChanged: (value) {
                                        setState(() {
                                          radius = value;
                                          updateFilteredStores();
                                        });
                                      },
                                    ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    height: isStoreListVisible ? 200.0 : 0.0,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(8.0),
                                      ),
                                      child: StoreListWidget(
                                        stores: filteredStores,
                                        onSelectStore: (LatLng destination) {
                                          final store = filteredStores.firstWhere(
                                            (store) =>
                                                store['coordinates']['lat'] == destination.latitude &&
                                                store['coordinates']['lng'] == destination.longitude,
                                            orElse: () => {},
                                          );
                                          setState(() {
                                            selectedStore = store.isNotEmpty ? store : null;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: -20.0,
                          left: 16.0,
                          child: FloatingActionButton(
                            onPressed: () {
                              setState(() {
                                isStoreListVisible = !isStoreListVisible;
                              });
                            },
                            child: Icon(
                              isStoreListVisible ? Icons.close : Icons.list,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -20.0,
                          right: 16.0,
                          child: FloatingActionButton(
                            onPressed: () {
                              if (currentLocation != null) {
                                if(isNavigating) {
                                  _mapController.move(currentLocation!, 20.0);
                                } else {
                                  _mapController.move(currentLocation!, 14.0);
                                }
                              }
                            },
                            child: const Icon(Icons.my_location),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selectedStore != null) 
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Card(
                        margin: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      selectedStore = null; // Ẩn thông tin chi tiết
                                    });
                                  },
                                ),
                              ],
                            ),
                            StoreDetailWidget(
                              name: selectedStore!['name'],
                              category: selectedStore!['category'] ?? 'Không xác định',
                              address: selectedStore!['address'],
                              coordinates: LatLng(
                                selectedStore!['coordinates']['lat'],
                                selectedStore!['coordinates']['lng'],
                              ),
                              phoneNumber: selectedStore!['phoneNumber'],
                              website: selectedStore!['website'],
                              priceLevel: selectedStore!['priceLevel'] ?? 'Không xác định',
                              openingHours: selectedStore!['openingHours'] ?? 'Không rõ',
                              imageURL: selectedStore!['imageURL'],
                              onGetDirections: () {
                                setState(() {
                                  shouldDrawRoute = true;
                                  isStoreListVisible = false;
                                });
                                updateRouteToStore(LatLng(
                                  selectedStore!['coordinates']['lat'],
                                  selectedStore!['coordinates']['lng'],
                                ));
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}