// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class StoreListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> stores;
  final Function(LatLng) onSelectStore;

  const StoreListWidget({
    required this.stores,
    required this.onSelectStore,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: stores.length,
        itemBuilder: (context, index) {
          final store = stores[index];
          final coordinates = store['coordinates'];
          return ListTile(
            title: Text(store['name']),
            subtitle: Text('Lat: ${coordinates['lat']}, Lng: ${coordinates['lng']}'),
            trailing: Icon(Icons.directions),
            onTap: () {
              onSelectStore(LatLng(coordinates['lat'], coordinates['lng']));
            },
          );
        },
      ),
    );
  }
}
