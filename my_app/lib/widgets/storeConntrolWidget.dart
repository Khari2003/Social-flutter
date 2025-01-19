// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/radiusSlider.dart';
import '../widgets/storeListWidget.dart';
import '../widgets/StoreDetailWidget.dart';

class StoreControls extends StatelessWidget {
  final bool isNavigating;
  final bool isStoreListVisible;
  final Function(double) onRadiusChanged;
  final Function(LatLng) onSelectStore;
  final Function() toggleStoreList;
  final Function() moveToCurrentLocation;
  final double radius;
  final List<Map<String, dynamic>> filteredStores;
  final Map<String, dynamic>? selectedStore;
  final Function() closeSelectedStore;
  final Function(LatLng) onGetDirections;

  const StoreControls({
    super.key,
    required this.isNavigating,
    required this.isStoreListVisible,
    required this.onRadiusChanged,
    required this.onSelectStore,
    required this.toggleStoreList,
    required this.moveToCurrentLocation,
    required this.radius,
    required this.filteredStores,
    required this.selectedStore,
    required this.closeSelectedStore,
    required this.onGetDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
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
                            onRadiusChanged: onRadiusChanged,
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
                              onSelectStore: onSelectStore,
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
                  onPressed: toggleStoreList,
                  child: Icon(
                    isStoreListVisible ? Icons.close : Icons.list,
                  ),
                ),
              ),
              Positioned(
                top: -20.0,
                right: 16.0,
                child: FloatingActionButton(
                  onPressed: moveToCurrentLocation,
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
                        onPressed: closeSelectedStore,
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
                    onGetDirections: () => onGetDirections(
                      LatLng(
                        selectedStore!['coordinates']['lat'],
                        selectedStore!['coordinates']['lng'],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
